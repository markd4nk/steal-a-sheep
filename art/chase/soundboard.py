"""Every chase sound on its own, numbered on a card, as the game would play it (speeds and cuts applied).

python soundboard.py <board> out.mp4 <dir for each sound as a WAV>; boards: alarms, sounds, alarms2, goddess, voices.
"""
import os, subprocess, sys, wave
import numpy as np
from PIL import Image, ImageDraw, ImageFont

WORK = os.environ.get("CHASE_WORK", os.path.expanduser("~/Videos/StealASheepTrailer/work/chase"))
FONT = "C:/Users/markf/Videos/StealASheepTrailer/work/FredokaOne-Regular.ttf"
SR = 48000
FPS = 10
W, H = 1280, 720
GAP = 0.9


def load(name):
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", f"{WORK}/snd/{name}.ogg", "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
        capture_output=True,
    ).stdout
    return np.frombuffer(raw, dtype=np.float32).copy()


cache = {}


def clip(name, speed=1.0, start=0.0, length=None, fade=0.03):
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


def norm(x, db=-3.0):
    """Each sound brought to the same loudness, so they can be compared by ear (in game the mix sets them)."""
    rms = np.sqrt(np.mean(x[np.abs(x) > 1e-4] ** 2)) if np.any(np.abs(x) > 1e-4) else 1
    y = x / (rms + 1e-9) * 10 ** ((db - 12) / 20)
    peak = np.max(np.abs(y))
    return y / peak * 0.95 if peak > 0.95 else y


def lay(parts, total=None):
    """Mix (time, samples, gain dB) parts into one clip."""
    end = max(t + len(x) / SR for t, x, _ in parts)
    out = np.zeros(int((total or end) * SR) + 1, dtype=np.float32)
    for t, x, g in parts:
        i = int(t * SR)
        j = min(len(out), i + len(x))
        out[i:j] += x[: j - i] * 10 ** (g / 20)
    return out


def steps(gap, seconds, gain_from, gain_to):
    parts = []
    t, k = 0.0, 0
    n = int(seconds / gap)
    rng = np.random.default_rng(3)
    while k < n:
        g = gain_from + (gain_to - gain_from) * k / max(1, n - 1)
        j = rng.uniform(-0.05, 0.05)
        parts.append((t, clip("boomy1", speed=1.2 + j, length=0.32, fade=0.15), g))
        d = clip("dragon23", speed=0.8 + j)
        parts.append((t, d / (np.max(np.abs(d)) + 1e-9) * 10 ** (-14 / 20), g + 2))
        t += gap
        k += 1
    return lay(parts)


def heartbeat(seconds):
    parts, t = [], 0.0
    while t < seconds:
        i = min(1.0, t / seconds)
        parts.append((t, clip("heart1", speed=1 + 0.35 * i, length=0.62, fade=0.08), -6 + 6 * i))
        t += 60 / (80 + 80 * i)
    return lay(parts)


def far_roar():
    y = clip("yellE", speed=0.72)
    a = np.exp(-2 * np.pi * 900 / SR)
    out = np.empty_like(y)
    acc = 0.0
    for k in range(len(y)):
        acc = (1 - a) * y[k] + a * acc
        out[k] = acc
    return lay([(0.0, out, 0), (0.35, out, -7), (0.7, out, -13)])


ALARMS = [
    ("A", "Red Alert alarm", "Low buzzy wenh... wenh... (a little faster than the file)", clip("redAlert1", speed=1.15, length=4.0 * 1.15, fade=0.3)),
    ("B", "Buzzy klaxon", "Higher, harsher, quicker pulses", clip("klaxonBuzzy", length=4.0, fade=0.3)),
    ("C", "Electronic alarm", "Clean beeping tone (APM)", clip("elecAlarmD", start=1.9, length=4.0, fade=0.3)),
    ("D", "Submarine dive klaxon", "The old ah-oo-gah", clip("dive", length=4.0, fade=0.3)),
    ("E", "Wee-oo siren", "Fast high-low, like a European police car", clip("neutralZone", length=4.0, fade=0.3)),
]

SOUNDS = [
    ("1", "The god's roar", "When it sees you steal (the two below, together)",
     lay([(0, clip("goblinRoar", speed=0.85), 0), (0.05, clip("yellE", speed=0.78), -3)])),
    ("1a", "Roar: the growl layer", "A human growl, slowed", clip("goblinRoar", speed=0.85)),
    ("1b", "Roar: the yell layer", "A man's yell, slowed so it's deeper", clip("yellE", speed=0.78)),
    ("2", "Footsteps, far", "The god running, a way behind", steps(0.34, 2.4, -14, -10)),
    ("3", "Footsteps, close", "The god right behind you", steps(0.3, 2.4, -2, 0)),
    ("4", "Chase yell 1", "Every few seconds while it runs", clip("yellB", speed=0.8)),
    ("5", "Chase yell 2", "", clip("yellD", speed=0.76)),
    ("6", "Right behind you", "A snarl at your back", clip("goblinRoar", speed=0.72, start=0.2, length=0.6, fade=0.15)),
    ("7", "Your heartbeat", "Calm to racing as the god closes", heartbeat(6.0)),
    ("8", "Chase music, god far", "Run For Your Life, no drums", clip("rfl80", start=4, length=7, fade=0.5)),
    ("9", "Chase music, god close", "The drums come in", clip("rflFull", start=4, length=7, fade=0.5)),
    ("10", "The punch", "Swing and hit", lay([(0, clip("whooshPunch"), 0), (0.2, norm(clip("bodyImpact")), 0), (0.2, norm(clip("boxing5")), -4)])),
    ("11", "The laugh", "When the god catches you", clip("laugh4", speed=0.8, start=0.3)),
    ("12", "Flying off", "After the punch", clip("whoosh", speed=0.75)),
    ("13", "Landing", "", clip("bodyImpact", speed=0.8)),
    ("14", "Safe", "Crossing the safety line", clip("saved")),
    ("15", "The god, far behind", "Its angry roar echoing as you get away", far_roar()),
    ("16", "Zeus's thunder", "Only if each god gets its own catch sound", clip("thunder")),
    ("17", "A goddess's yell 1", "Not in the video: Hera, Athena and the others", clip("fyell8", speed=0.9)),
    ("18", "A goddess's yell 2", "", clip("fyell10", speed=0.9)),
    ("19", "A goddess's laugh", "", clip("flaugh", speed=0.9, start=0.4, length=3.2, fade=0.3)),
]

# The second alarm board (2026-10-06): the user liked A and C and asked for something in between.
ALARMS2 = [
    ("A", "Red Alert alarm (in the game now)", "Low and buzzy", clip("redAlert1", speed=1.15, length=4.0 * 1.15, fade=0.3)),
    ("C", "Electronic alarm", "Clean, higher beeping (APM)", clip("elecAlarmD", start=1.9, length=4.0, fade=0.3)),
    ("F", "Low console alarm", "Cleaner than A, lower than C, A's pace", clip("consoleLow", start=0.2, length=4.0, fade=0.3)),
    ("G", "Steady-tone alarm", "C's family: smooth tones, a bit lower (APM)", clip("elecF", start=1.1, length=4.0, fade=0.3)),
    ("H", "Long-tone alarm", "C's family: longer, lower tones (APM)", clip("elecAlarmE", start=1.0, length=4.0, fade=0.3)),
    ("I", "C, deeper", "C slowed down: lower and a little slower", clip("elecAlarmD", speed=0.75, start=1.9, length=4.0 * 0.75, fade=0.3)),
    ("J", "A and C together", "The low buzz under the clean beep", lay([
        (0, norm(clip("redAlert1", speed=1.15, length=4.0 * 1.15, fade=0.3)), -2),
        (0, norm(clip("elecAlarmD", start=1.9, length=4.0, fade=0.3)), -5),
    ])),
]


def depths(tag, name, make):
    """The same goddess sound now, deeper and deepest."""
    return [
        (f"{tag}", f"{name}: now", "As in the game today", make(1.0)),
        (f"{tag}+", f"{name}: deeper", "", make(0.86)),
        (f"{tag}++", f"{name}: deepest", "", make(0.76)),
    ]


# The goddesses at three depths (2026-10-06): the user asked for them deeper, "they're still huge beings".
GODDESS = (
    depths("G1", "A goddess's roar", lambda k: lay([(0, clip("goblinRoar", speed=0.85 * k), 0), (0.05, norm(clip("fyell8", speed=0.9 * k)), -4)]))
    + depths("G2", "A goddess's yell 1", lambda k: clip("fyell8", speed=0.9 * k))
    + depths("G3", "A goddess's yell 2", lambda k: clip("fyell10", speed=0.9 * k))
    + depths("G4", "A goddess's laugh", lambda k: clip("flaugh", speed=0.9 * k, start=0.4, length=3.2, fade=0.3))
)

# One voice each (2026-10-06): the user heard the layered roar (a growl under a yell) and the goddess laugh (a file of
# several different laughs) as more than one person. Every option here is one person in one take, as the game plays it.
VOICES = [
    ("M1", "A god's roar: a man's yell", "Slowed so it's huge (the old roar's top layer)", clip("yellE", speed=0.78)),
    ("M2", "A god's roar: a growl", "A man's growl, slowed (the old roar's bottom layer)", clip("goblinRoar", speed=0.85)),
    ("M3", "A god's roar: a shorter yell", "", clip("yellD", speed=0.72)),
    ("M4", "A god's roar: another yell", "", clip("my_9125652955", speed=0.72)),
    ("F1", "A goddess's roar: one woman's yell", "Slowed like the goddesses' other sounds", clip("fy_9114399675", speed=0.77)),
    ("F2", "A goddess's roar: a lower yell", "", clip("fy_9114399696", speed=0.77)),
    ("F3", "A goddess's roar: a sharper yell", "", clip("fy_9114399178", speed=0.77)),
    ("ML1", "A god's laugh (in the game now)", "The HA HA HA you liked", clip("laugh4", speed=0.8, start=0.3)),
    ("ML2", "A god's laugh: faster", "", clip("ml_9116239157", speed=0.8, start=0.3, length=2.6, fade=0.3)),
    ("ML3", "A god's laugh: longer", "", clip("ml_9116239334", speed=0.8, start=0.3, length=3.2, fade=0.4)),
    ("FL1", "A goddess's laugh: a cackle", "One woman, one take", clip("fl_9113043479", speed=0.8, start=0.2)),
    ("FL2", "A goddess's laugh: giggle to cackle", "", clip("fl_9113043410", speed=0.8)),
    ("FL3", "A goddess's laugh: bigger", "", clip("fl_9114396740", speed=0.8, start=0.2)),
    ("FY1", "A goddess's chase yell 1", "One woman (the old ones had two)", clip("fy_9114399869", speed=0.77)),
    ("FY2", "A goddess's chase yell 2", "", clip("fy_9114399465", speed=0.77)),
]

font_big = ImageFont.truetype(FONT, 84)
font_name = ImageFont.truetype(FONT, 60)
font_line = ImageFont.truetype(FONT, 36)
INK = (21, 42, 85)


def card(tag, name, line, progress):
    img = Image.new("RGB", (W, H), INK)
    d = ImageDraw.Draw(img)
    d.text((80, 170), tag, font=font_big, fill=(255, 205, 60))
    d.text((80, 300), name, font=font_name, fill=(255, 255, 255))
    if line:
        d.text((80, 390), line, font=font_line, fill=(170, 190, 230))
    d.rounded_rectangle((80, 520, W - 80, 540), radius=10, fill=(40, 66, 120))
    if progress > 0:
        d.rounded_rectangle((80, 520, 80 + int((W - 160) * min(1, progress)), 540), radius=10, fill=(255, 205, 60))
    return img


def render(items, out, outdir):
    os.makedirs(outdir, exist_ok=True)
    audio, spans, t = [], [], 0.6
    for tag, name, line, x in items:
        x = norm(x)
        spans.append((t, t + len(x) / SR, tag, name, line))
        # Each one alone too, so it can be replayed.
        single = f"{outdir}/{tag}.wav"
        with wave.open(single, "wb") as w:
            w.setnchannels(1), w.setsampwidth(2), w.setframerate(SR)
            w.writeframes((np.clip(np.concatenate([np.zeros(SR // 5), x]), -1, 1) * 32767).astype(np.int16).tobytes())
        t += len(x) / SR + GAP
    total = t
    mix = np.zeros(int(total * SR) + SR, dtype=np.float32)
    for (a, _, _, _, _), (_, _, _, x) in zip(spans, items):
        x = norm(x)
        mix[int(a * SR) : int(a * SR) + len(x)] += x
    with wave.open(f"{WORK}/board.wav", "wb") as w:
        w.setnchannels(1), w.setsampwidth(2), w.setframerate(SR)
        w.writeframes((np.clip(mix[: int(total * SR)], -1, 1) * 32767).astype(np.int16).tobytes())
    enc = subprocess.Popen(
        ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
         "-i", f"{WORK}/board.wav", "-c:v", "libx264", "-tune", "stillimage", "-crf", "24", "-pix_fmt", "yuv420p",
         "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", out],
        stdin=subprocess.PIPE,
    )
    cards = {}
    for f in range(int(total * FPS)):
        now = f / FPS
        current = spans[0]
        for s in spans:
            if now >= s[0] - GAP / 2:
                current = s
        a, b, tag, name, line = current
        progress = round((now - a) / (b - a), 1) if b > a else 0
        key = (tag, progress)
        if key not in cards:
            cards[key] = card(tag, name, line, max(0, progress)).tobytes()
        enc.stdin.write(cards[key])
    enc.stdin.close()
    enc.wait()
    print(out, f"{total:.1f}s")


BOARDS = {"alarms": ALARMS, "sounds": SOUNDS, "alarms2": ALARMS2, "goddess": GODDESS, "voices": VOICES}
render(BOARDS[sys.argv[1]], sys.argv[2], sys.argv[3])
