import os
WORK = os.environ.get("CHASE_WORK", os.path.expanduser("~/Videos/StealASheepTrailer/work/chase"))
os.makedirs(f"{WORK}/snd", exist_ok=True)
import json, sys, urllib.request, urllib.parse, time
LIC = {7462895450: "PSE", 7462718749: "APM"}
def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)
def search(kw, num=30):
    url = "https://apis.roblox.com/toolbox-service/v1/marketplace/3?" + urllib.parse.urlencode({"keyword": kw, "num": num})
    data = get(url)
    ids = [d["id"] for d in data.get("data", [])]
    out = []
    for i in range(0, len(ids), 25):
        chunk = ids[i:i+25]
        det = get("https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=" + ",".join(map(str, chunk)))
        for d in det.get("data", []):
            a = d.get("asset", {}); c = d.get("creator", {})
            lic = LIC.get(c.get("id"))
            if not lic: continue
            out.append((a.get("id"), lic, a.get("duration"), a.get("name"), (a.get("description") or "")[:110].replace("\n", " ")))
    return out
for kw in sys.argv[1:]:
    try:
        res = search(kw)
    except Exception as e:
        print("##", kw, "ERR", e); continue
    print("##", kw, len(res))
    for r in res:
        print(f"  {r[0]} {r[1]} {r[2]}s | {r[3]} | {r[4]}")
    time.sleep(0.3)
