"""Chase terror mock-up: last night's trailer takes with the proposed sound design and red danger screen.

Audio is mixed here from Roblox's licensed sounds (downloaded to snd/); video is the raw takes, graded per frame.
"""
import os
WORK = os.environ.get("CHASE_WORK", os.path.expanduser("~/Videos/StealASheepTrailer/work/chase"))
os.makedirs(f"{WORK}/snd", exist_ok=True)

import math, random, subprocess, sys, wave
import numpy as np
from PIL import Image, ImageDraw, ImageFont

RAW = "C:/Users/markf/Videos/StealASheepTrailer/raw"
FONT = "C:/Users/markf/Videos/StealASheepTrailer/work/FredokaOne-Regular.ttf"
OUT = sys.argv[1] if len(sys.argv) > 1 else f"{WORK}/chase_mockup.mp4"
SR = 48000
FPS = 30
W, H = 1280, 720
PW, PH = 1320, 742  # decoded a little larger, so the shake can crop

# The edit, in output seconds.
SEG1 = (0.0, 10.0)  # steal_chase2 0.6-10.6: steal, Poseidon's alert, the chase
SEG2 = (10.0, 16.1)  # caught2 2.9-9.0: Zeus closes in and punches
CARD = (16.1, 16.9)
SEG3 = (16.9, 19.4)  # steal_chase2 15.4-17.9: reaching safety
TOTAL = 19.4
STEAL, ALERT, RUN, CLOSE, PUNCH, LAND, SAFE = 1.5, 2.8, 4.4, 10.0, 12.05, 15.1, 17.6

random.seed(7)


def intensity(t: float) -> float:
    """How close the god is, 0 (no chase) to 1 (right behind you)."""
    if t < STEAL:
        return 0.0
    if t < RUN:
        return 0.3
    if t < CLOSE:
        return 0.35 + 0.25 * (t - RUN) / (CLOSE - RUN)
    if t < PUNCH:
        return 0.75 + 0.25 * (t - CLOSE) / (PUNCH - CLOSE)
    if t < SEG3[0]:
        return 0.0
    if t < SAFE:
        return 0.5
    return max(0.0, 0.5 * (1 - (t - SAFE) / 1.2))


# ---------------------------------------------------------------- audio
def load(name: str) -> np.ndarray:
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", f"{WORK}/snd/{name}.ogg", "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
        capture_output=True,
    ).stdout
    return np.frombuffer(raw, dtype=np.float32).copy()


cache: dict = {}


def clip(name, speed=1.0, start=0.0, length=None, fade=0.03):
    """Like a Roblox Sound: PlaybackSpeed changes speed and pitch together; Start/Length are in the file's seconds."""
    if name not in cache:
        cache[name] = load(name)
    x = cache[name]
    a = int(start * SR)
    b = len(x) if length is None else min(len(x), a + int(length * SR))
    x = x[a:b]
    if speed != 1.0:
        n = int(len(x) / speed)
        x = np.interp(np.arange(n) * speed, np.arange(len(x)), x).astype(np.float32)
    f = min(len(x), int(fade * SR))
    if f > 0:
        x = x.copy()
        x[-f:] *= np.linspace(1, 0, f)
    return x


def lowpass(x, cutoff):
    a = math.exp(-2 * math.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):  # short clips only
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


def peak_norm(x, db):
    return x / (np.max(np.abs(x)) + 1e-9) * 10 ** (db / 20)


mix = np.zeros(int(TOTAL * SR) + SR, dtype=np.float32)


def put(t, x, db=0.0, env=None):
    i = int(t * SR)
    x = x * 10 ** (db / 20)
    if env is not None:
        x = x * env(np.arange(len(x)) / SR + t)
    j = min(len(mix), i + len(x))
    mix[i:j] += x[: j - i]


def db_gain(d):
    return 10 ** (d / 20)


# Calm before the steal: the meadow and the calm music, cut dead by the alarm.
birds = clip("birds")
duck = lambda t: np.where(t < STEAL, 1.0, np.where(t < SAFE, 0.25, np.clip(0.25 + (t - SAFE) / 1.5, 0.25, 1.0)))
put(0, birds[: int(TOTAL * SR)], 8, env=lambda t: duck(t) * np.where((t > SEG2[1]) & (t < SEG3[0]), 0, 1))
calm = clip("playtime", start=20, length=STEAL + 0.05, fade=0.06)
put(0, calm, -12)

# The steal: the alarm, then the god's roar during the head start.
put(STEAL, clip("alarmTag2"), -2, env=lambda t: np.where(t < ALERT, 1.0, 0.65) * np.clip(1 - (t - RUN) / 0.8, 0, 1))
put(ALERT, clip("goblinRoar", speed=0.85), 0)
put(ALERT + 0.05, clip("yellE", speed=0.78), -3)

# Chase music: Run For Your Life's drumless underscore all along, its full mix (with drums) fading in as the god
# closes; both are APM mixes of one track and start together. Hard stop on the punch.
under = clip("rfl80", start=0)
full = clip("rflFull", start=0)
MUS0 = STEAL + 0.1


def music_env(layer):
    def env(t):
        i = np.interp(t, *zip(*[(x, intensity(x)) for x in np.arange(0, TOTAL, 0.05)]))
        drums = np.clip((i - 0.42) / 0.33, 0, 1)
        g = drums if layer == "full" else (1 - 0.6 * drums)
        fade_in = np.clip((t - MUS0) / 0.8, 0, 1)
        on = (t < PUNCH) | ((t >= SEG3[0]) & (t < SAFE))
        return g * fade_in * on
    return env


for layer, x, gain in (("under", under, 2), ("full", full, -5)):
    put(MUS0, x[: int((PUNCH - MUS0) * SR)], gain, env=music_env(layer))
    # The escape: the same chase, picked up again after the card, cut at the safety line.
    put(SEG3[0], x[int(20 * SR) : int((20 + SAFE - SEG3[0]) * SR)], gain, env=lambda t, l=layer: music_env(l)(t))

# The thief's heartbeat: one lub-dub from the APM horror kit, retriggered faster as the god closes.
beat = clip("heart1", start=0.0, length=0.62, fade=0.08)
beats = []
t = STEAL + 0.3
while t < TOTAL:
    i = intensity(t)
    if i <= 0.01:
        t += 0.1
        continue
    bpm = 80 + 80 * i
    put(t, clip("heart1", speed=1 + 0.35 * i, start=0, length=0.62, fade=0.08), -7 + 9 * i)
    beats.append(t)
    t += 60 / bpm

# The god's footsteps: a giant's thud (the attack of a boomy dinosaur step) with a dragon's foley on top, every
# stride while it runs, louder as it closes.
steps = []
t = RUN + 0.15
while t < TOTAL:
    i = intensity(t)
    running = (RUN <= t < PUNCH) or (SEG3[0] <= t < SAFE)
    if running:
        jitter = random.uniform(-0.05, 0.05)
        thud = clip("boomy1", speed=1.2 + jitter, start=0, length=0.32, fade=0.15)
        crunch = peak_norm(clip("dragon23", speed=0.8 + jitter), -14)
        put(t, thud, -26 + 24 * i)
        put(t, crunch, -24 + 20 * i)
        steps.append((t, i))
    t += 0.34

# The god's voice while it runs: short angry yells, nearer and louder.
put(6.2, clip("yellB", speed=0.8), -12)
put(8.6, clip("goblinRoar", speed=0.8, length=1.0, fade=0.2), -10)
put(10.6, clip("yellD", speed=0.76), -3)
put(11.45, clip("goblinRoar", speed=0.72, start=0.2, length=0.6, fade=0.15), -1)

# Caught: the swing, the hit, Zeus's thunder, the laugh, the flight and the landing.
put(PUNCH - 0.2, clip("whooshPunch"), -2)
put(PUNCH, peak_norm(clip("bodyImpact"), -3), 0)
put(PUNCH, peak_norm(clip("boxing5"), -6), 0)
put(PUNCH + 0.02, clip("thunder"), -1)
put(PUNCH + 0.35, clip("laugh4", speed=0.8, start=0.3), 2)
put(PUNCH + 0.15, clip("whoosh", speed=0.75), -8)
put(LAND, peak_norm(clip("bodyImpact", speed=0.8), -8), 0)

# Safe: the music cut, a bright release, and the god's frustrated roar far behind, echoing off the mountain.
put(SAFE - 0.08, clip("whoosh", speed=1.3), -12)
put(SAFE, clip("saved"), -3)
far = lowpass(clip("yellE", speed=0.72), 900)
for k, (d, g) in enumerate(((0.3, -15), (0.65, -22), (1.0, -28))):
    put(SAFE + d, far, g)

# Master: a gentle limiter.
peak = np.max(np.abs(mix))
mix = np.tanh(mix / peak * 1.6) / math.tanh(1.6) * 0.89
pcm = (np.clip(mix[: int(TOTAL * SR)], -1, 1) * 32767).astype(np.int16)
with wave.open(f"{WORK}/mix.wav", "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("audio mixed", len(beats), "beats", len(steps), "steps")

# ---------------------------------------------------------------- video
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2) / math.sqrt(2)
VIG = np.clip((r - 0.32) / 0.5, 0, 1) ** 1.6  # 0 in the middle, 1 in the corners
VIG = VIG[..., None]
RED = np.array([170, 0, 8], dtype=np.float32)

font_small = ImageFont.truetype(FONT, 30)
font_card = ImageFont.truetype(FONT, 64)


def label(text, font):
    box = font.getbbox(text)
    img = Image.new("RGBA", (box[2] + 24, box[3] + 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.text((12, 8), text, font=font, fill=(255, 255, 255, 255), stroke_width=4, stroke_fill=(21, 42, 85, 255))
    return img


CAPTIONS = [
    (STEAL, ALERT, "Steal"),
    (ALERT, RUN, "The god sees you"),
    (RUN, CLOSE, "Run"),
    (CLOSE, PUNCH, "Right behind you"),
    (PUNCH, SEG2[1], "Caught"),
    (SEG3[0], SAFE, "Or you get away"),
    (SAFE, TOTAL, "Safe"),
]
caption_imgs = {c[2]: label(c[2], font_small) for c in CAPTIONS}
card_img = label("Or you get away", font_card)


def pulse(t, times, decay):
    v = 0.0
    for b in times:
        if b <= t < b + 1:
            v = max(v, math.exp(-(t - b) / decay))
    return v


beat_arr = np.array(beats)
src = (
    f"[0:v]trim=0.6:10.6,setpts=PTS-STARTPTS,fps={FPS},scale={PW}:{PH},setsar=1[a];"
    f"[1:v]trim=2.9:9.0,setpts=PTS-STARTPTS,fps={FPS},scale={PW}:{PH},setsar=1[b];"
    f"color=black:s={PW}x{PH}:d={CARD[1]-CARD[0]}:r={FPS},format=yuv420p,setsar=1[c];"
    f"[0:v]trim=15.4:17.9,setpts=PTS-STARTPTS,fps={FPS},scale={PW}:{PH},setsar=1[d];"
    f"[a][b][c][d]concat=n=4:v=1:a=0,format=rgb24[v]"
)
dec = subprocess.Popen(
    ["ffmpeg", "-v", "error", "-i", f"{RAW}/steal_chase2.mkv", "-i", f"{RAW}/caught2.mkv", "-filter_complex", src,
     "-map", "[v]", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
    stdout=subprocess.PIPE,
)
enc = subprocess.Popen(
    ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
     "-i", f"{WORK}/mix.wav", "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
     "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", OUT],
    stdin=subprocess.PIPE,
)
frame_bytes = PW * PH * 3
n = 0
while True:
    buf = dec.stdout.read(frame_bytes)
    if len(buf) < frame_bytes:
        break
    t = n / FPS
    n += 1
    img = np.frombuffer(buf, dtype=np.uint8).reshape(PH, PW, 3)
    i = intensity(t)
    # Shake: the god's roar, its steps when it's right behind, and the punch.
    amp = 0.0
    if ALERT <= t < ALERT + 0.5:
        amp = max(amp, 5 * (1 - (t - ALERT) / 0.5))
    for st, si in steps:
        if si > 0.72 and st <= t < st + 0.12:
            amp = max(amp, 3.0)
    if PUNCH <= t < PUNCH + 0.4:
        amp = max(amp, 12 * (1 - (t - PUNCH) / 0.4))
    dx = int(random.uniform(-amp, amp))
    dy = int(random.uniform(-amp, amp))
    ox, oy = (PW - W) // 2 + dx, (PH - H) // 2 + dy
    f = img[oy : oy + H, ox : ox + W].astype(np.float32)
    # The steal's zoom punch.
    if STEAL <= t < STEAL + 0.35:
        z = 1 + 0.06 * (1 - (t - STEAL) / 0.35)
        cw, ch = int(W / z), int(H / z)
        x0, y0 = (W - cw) // 2, (H - ch) // 2
        f = np.asarray(
            Image.fromarray(f[y0 : y0 + ch, x0 : x0 + cw].astype(np.uint8)).resize((W, H), Image.BILINEAR)
        ).astype(np.float32)
    # Danger grade: a little colour drained and a red cast as the god closes.
    if i > 0:
        grey = f.mean(axis=2, keepdims=True)
        f = f + (grey - f) * (0.35 * i)
        f = f * np.array([1.0, 1 - 0.12 * i, 1 - 0.12 * i], dtype=np.float32)
    # The red edges: steady with the chase, a throb on every heartbeat.
    hb = pulse(t, beat_arr, 0.16) if i > 0 else 0.0
    alpha = (0.25 + 0.5 * i) * (1 if i > 0 else 0) + hb * (0.12 + 0.3 * i)
    after = 0.0
    if PUNCH <= t < PUNCH + 0.8:  # the red bleeds away after the hit
        after = 0.9 * (1 - (t - PUNCH) / 0.8)
    alpha = min(1.0, max(alpha, after))
    if alpha > 0:
        a = VIG * alpha
        f = f * (1 - a) + RED * a
    # Flashes: red on the steal, white on the punch, a soft warm one on reaching safety.
    for at, dur, col, peak_a in ((STEAL, 0.45, (220, 20, 20), 0.45), (PUNCH, 0.3, (255, 255, 255), 0.75), (SAFE, 0.5, (255, 240, 200), 0.25)):
        if at <= t < at + dur:
            k = peak_a * (1 - (t - at) / dur)
            f = f * (1 - k) + np.array(col, dtype=np.float32) * k
    out = Image.fromarray(np.clip(f, 0, 255).astype(np.uint8))
    if CARD[0] <= t < CARD[1]:
        out.paste(card_img, ((W - card_img.width) // 2, (H - card_img.height) // 2), card_img)
    else:
        for a0, a1, text in CAPTIONS:
            if a0 <= t < a1:
                cap = caption_imgs[text]
                out.paste(cap, (28, H - cap.height - 24), cap)
    enc.stdin.write(out.tobytes())
enc.stdin.close()
enc.wait()
dec.wait()
print("frames", n, "->", OUT)
