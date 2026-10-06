import os
import subprocess, sys, numpy as np
WORK = os.environ.get("CHASE_WORK", os.path.expanduser("~/Videos/StealASheepTrailer/work/chase"))
SR=16000
def load(n, start=0, dur=8):
    raw = subprocess.run(["ffmpeg","-v","error","-ss",str(start),"-t",str(dur),"-i",f"{WORK}/snd/{n}.ogg","-ac","1","-ar",str(SR),"-f","f32le","-"],capture_output=True).stdout
    return np.frombuffer(raw,dtype=np.float32)
for arg in sys.argv[1:]:
    n, _, st = arg.partition("@"); st = float(st or 0)
    x = load(n, st)
    if len(x) < SR: print(n, "short"); continue
    hop = SR//100
    env = np.array([np.sqrt(np.mean(x[i:i+hop]**2)) for i in range(0, len(x)-hop, hop)])
    db = 20*np.log10(env+1e-9); pk = db.max()
    onset = np.argmax(db > pk-20)/100
    e = env - env.mean(); ac = np.correlate(e,e,"full")[len(e)-1:]
    per = (20+np.argmax(ac[20:200]))/100; rhythm = ac[int(per*100)]/ac[0]
    # spectrum of loud frames
    loud = [i for i in range(len(env)) if db[i] > pk-6]
    S = np.zeros(1025)
    for i in loud[:200]:
        seg = x[i*hop:i*hop+2048]
        if len(seg) < 2048: continue
        S += np.abs(np.fft.rfft(seg*np.hanning(2048)))
    f = np.fft.rfftfreq(2048, 1/SR)
    f0 = f[np.argmax(S[5:])+5]
    cent = (S*f).sum()/S.sum()
    flat = np.exp(np.mean(np.log(S[5:]+1e-9)))/np.mean(S[5:])  # 0 = pure tone, 1 = noise
    # active rms
    act = env[db > pk-15]; arms = 20*np.log10(np.sqrt(np.mean(act**2)))
    strip = "".join(" .:-=+*#%@"[max(0,min(9,int((d-pk+30)/3)))] for d in db[int(onset*100):int(onset*100)+400:8])
    print(f"{arg:14s} onset={onset:4.1f} pulse={per:.2f}s({1/per:.1f}/s,{rhythm:.2f}) peakHz={f0:5.0f} cent={cent:5.0f} buzz={flat:.3f} rms={arms:5.1f} |{strip}|")
