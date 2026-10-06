import os
WORK = os.environ.get("CHASE_WORK", os.path.expanduser("~/Videos/StealASheepTrailer/work/chase"))
os.makedirs(f"{WORK}/snd", exist_ok=True)
import json, sys, urllib.request, gzip, os, subprocess
def get(url, raw=False):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0", "Accept-Encoding": "gzip"})
    with urllib.request.urlopen(req, timeout=60) as r:
        data = r.read()
        if data[:2] == b"\x1f\x8b":
            data = gzip.decompress(data)
        return data if raw else json.loads(data)
for pair in sys.argv[1:]:
    name, aid = pair.split("=")
    path = f"{WORK}/snd/{name}.ogg"
    if os.path.exists(path):
        continue
    try:
        meta = get(f"https://assetdelivery.roblox.com/v2/assetId/{aid}")
        loc = meta["locations"][0]["location"]
        data = get(loc, raw=True)
        open(path, "wb").write(data)
        dur = subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0",path],capture_output=True,text=True).stdout.strip()
        print(name, aid, len(data), dur)
    except Exception as e:
        print(name, aid, "ERR", e)
