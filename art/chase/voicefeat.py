import os
import subprocess, sys, glob, os, numpy as np
WORK = os.environ.get("CHASE_WORK", os.path.expanduser("~/Videos/StealASheepTrailer/work/chase"))
SR = 16000
def load(n):
    raw = subprocess.run(["ffmpeg","-v","error","-i",f"{WORK}/snd/{n}.ogg","-ac","1","-ar",str(SR),"-f","f32le","-"],capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32)
def yin_f0(frame):
    # simple normalized autocorrelation pitch, 70-700 Hz
    frame = frame - frame.mean()
    if np.sqrt(np.mean(frame**2)) < 1e-4: return 0, 0
    ac = np.correlate(frame, frame, "full")[len(frame)-1:]
    lo, hi = SR//700, SR//70
    i = lo + np.argmax(ac[lo:hi]); conf = ac[i]/ac[0]
    return SR/i, conf
names = sys.argv[1:]
for n in names:
    x = load(n); hop = SR//100; win = 640
    env = np.array([np.sqrt(np.mean(x[i:i+hop]**2)) for i in range(0, len(x)-hop, hop)])
    db = 20*np.log10(env+1e-9); pk = db.max()
    act = db > pk - 25
    # segments: active runs, merging gaps < 8 frames (80 ms)
    segs, i = [], 0
    while i < len(act):
        if act[i]:
            j = i
            while j < len(act) and (act[j] or (j+8 < len(act) and act[j:j+8].any())): j += 1
            if j - i >= 5: segs.append((i/100, j/100))
            i = j
        else: i += 1
    f0s = []
    for k in range(0, len(x)-win, hop):
        if db[min(k//hop, len(db)-1)] < pk - 12: continue
        f, c = yin_f0(x[k:k+win])
        if c > 0.5: f0s.append(f)
    f0s = np.array(f0s)
    if len(f0s) > 3:
        med = np.median(f0s); semis = 12*np.log2(f0s/med)
        spread = np.percentile(semis, 90) - np.percentile(semis, 10); voiced = len(f0s)
    else: med, spread, voiced = 0, 0, len(f0s)
    segtxt = " ".join(f"{a:.2f}-{b:.2f}" for a, b in segs[:6])
    strip = "".join(" .:-=+*#%@"[max(0,min(9,int((d-pk+30)/3)))] for d in db[::5][:80])
    print(f"{n:18s} dur={len(x)/SR:4.1f} segs={len(segs)} [{segtxt}] f0={med:4.0f}Hz spread={spread:4.1f}st voicedFrames={voiced:3d} |{strip}|")
