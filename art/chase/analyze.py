import os
WORK = os.environ.get("CHASE_WORK", os.path.expanduser("~/Videos/StealASheepTrailer/work/chase"))
os.makedirs(f"{WORK}/snd", exist_ok=True)
import subprocess, sys, numpy as np, glob, os
SR = 22050
def load(path):
    raw = subprocess.run(["ffmpeg","-v","error","-i",path,"-ac","1","-ar",str(SR),"-f","f32le","-"],capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32)
def f0(seg):
    seg = seg - seg.mean()
    if np.max(np.abs(seg)) < 1e-4: return 0, 0
    ac = np.correlate(seg, seg, "full")[len(seg)-1:]
    lo, hi = SR//600, SR//70
    i = lo + np.argmax(ac[lo:hi])
    return SR / i, ac[i] / ac[0]
names = sys.argv[1:] or sorted(os.path.basename(p)[:-4] for p in glob.glob(f"{WORK}/snd/*.ogg"))
for n in names:
    x = load(f"{WORK}/snd/{n}.ogg")
    hop = SR // 20
    fr = len(x) // hop
    rms = np.array([np.sqrt(np.mean(x[i*hop:(i+1)*hop]**2)) for i in range(fr)])
    db = 20*np.log10(rms + 1e-9)
    peak = db.max()
    active = np.where(db > peak - 20)[0]
    start, end = (active[0]*0.05, (active[-1]+1)*0.05) if len(active) else (0, 0)
    # centroid & f0 over the loudest 10 frames
    top = np.argsort(rms)[-10:]
    cents, f0s, vs = [], [], []
    for i in top:
        seg = x[i*hop:(i+1)*hop]
        spec = np.abs(np.fft.rfft(seg * np.hanning(len(seg))))
        freqs = np.fft.rfftfreq(len(seg), 1/SR)
        cents.append((spec*freqs).sum()/max(spec.sum(),1e-9))
        f, v = f0(x[i*hop:i*hop+2048] if i*hop+2048 < len(x) else seg)
        f0s.append(f); vs.append(v)
    # coarse envelope string (0.25 s cells)
    cells = [db[i:i+5].max() if len(db[i:i+5]) else -90 for i in range(0, fr, 5)]
    env = "".join(" .:-=+*#%@"[max(0,min(9,int((c-peak+45)/5)))] for c in cells[:60])
    print(f"{n:14s} dur={len(x)/SR:5.2f} peak={peak:6.1f}dB rms={20*np.log10(np.sqrt(np.mean(x**2))+1e-9):6.1f} act={start:4.2f}-{end:4.2f} cent={np.median(cents):5.0f} f0={np.median(f0s):4.0f} voiced={np.median(vs):.2f} |{env}|")
