"""Uploads the store's product and pass icons (make_product_icons.py's PNGs) to Roblox through Open Cloud, each as the
picture of its developer product or game pass, and checks every one took: its icon asset id must change.

    python art/store/upload_product_icons.py [<icons folder>] [--only Key1,Key2] [--dry-run] [--again]

Items uploaded before (uploaded.json says so) are skipped, so a failed run can be rerun; --again uploads them anew.

Reads the ids from src/shared/Config/Store.luau and the API key from the file ROBLOX_OPEN_CLOUD_KEY names (default
~/.roblox/steal-a-sheep-open-cloud.key: Creator Hub key "Steal a Sheep products and passes", developer-product and
game-pass read and write, this game only). The icons folder defaults to the T3 Code attachments' product_icons. Sends
only the picture (Open Cloud's PATCH changes just the fields given), a request every 1.5 s, and writes
uploaded.json beside the icons: each key's icon asset id before and after.
"""

import json
import os
import pathlib
import re
import sys
import time
import urllib.error
import urllib.request
import uuid

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
UNIVERSE = 10769564664
API = "https://apis.roblox.com"
DEFAULT_ICONS = pathlib.Path.home() / ".t3" / "userdata" / "attachments" / "product_icons"
DEFAULT_KEY = pathlib.Path.home() / ".roblox" / "steal-a-sheep-open-cloud.key"
SPACING = 1.5


def items():
    """(key, kind, id) for every product and pass with a Creator Hub id, in Config/Store's order."""
    store = (ROOT / "src" / "shared" / "Config" / "Store.luau").read_text(encoding="utf-8")
    products = re.search(r"local PRODUCT_IDS[^=]*= \{([^{}]*)\}", store).group(1)
    passes = re.search(r"local PASS_IDS[^=]*= \{([^{}]*)\}", store).group(1)
    found = [(key, "product", int(value)) for key, value in re.findall(r'\["([\w.]+)"\] = (\d+)', products)]
    found += [(key, "pass", int(value)) for key, value in re.findall(r"(\w+) = (\d+)", passes)]
    return found


def request(method, url, key, body=None, content_type=None):
    headers = {"x-api-key": key, "User-Agent": "steal-a-sheep-tools"}
    if content_type:
        headers["Content-Type"] = content_type
    for attempt in range(5):
        req = urllib.request.Request(url, data=body, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                raw = response.read()
                return response.status, json.loads(raw) if raw else None
        except urllib.error.HTTPError as error:
            if error.code == 429 or error.code >= 500:
                time.sleep(4 * (attempt + 1))
                continue
            return error.code, error.read().decode("utf-8", "replace")[:400]
    return 0, "gave up after retries"


def resource(kind, item_id):
    if kind == "product":
        return f"{API}/developer-products/v2/universes/{UNIVERSE}/developer-products/{item_id}"
    return f"{API}/game-passes/v1/universes/{UNIVERSE}/game-passes/{item_id}"


def icon_of(kind, item_id, key):
    status, body = request("GET", resource(kind, item_id) + "/creator", key)
    if status != 200 or not isinstance(body, dict):
        return None
    return body.get("iconImageAssetId") if kind == "product" else body.get("iconAssetId")


def multipart(path):
    boundary = uuid.uuid4().hex
    head = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="imageFile"; filename="{path.name}"\r\n'
        "Content-Type: image/png\r\n\r\n"
    ).encode()
    return head + path.read_bytes() + f"\r\n--{boundary}--\r\n".encode(), f"multipart/form-data; boundary={boundary}"


def main():
    args = sys.argv[1:]
    dry = "--dry-run" in args
    again = "--again" in args
    args = [a for a in args if a not in ("--dry-run", "--again")]
    only = None
    if "--only" in args:
        at = args.index("--only")
        only = set(args[at + 1].split(","))
        del args[at:at + 2]
    folder = pathlib.Path(args[0]) if args else DEFAULT_ICONS
    key_path = pathlib.Path(os.environ.get("ROBLOX_OPEN_CLOUD_KEY", DEFAULT_KEY))
    key = key_path.read_text(encoding="utf-8").strip()
    todo = [item for item in items() if only is None or item[0] in only]
    log_path = folder / "uploaded.json"
    log = json.loads(log_path.read_text(encoding="utf-8")) if log_path.exists() else {}
    failed = []
    for item_key, kind, item_id in todo:
        if log.get(item_key, {}).get("Ok") and not again:
            continue
        picture = folder / f"{item_key}.png"
        if not picture.exists():
            print(f"{item_key}: no {picture.name}")
            failed.append(item_key)
            continue
        before = icon_of(kind, item_id, key)
        time.sleep(SPACING)
        if dry:
            print(f"{item_key} ({kind} {item_id}): icon {before}, would upload {picture.name}")
            continue
        body, content_type = multipart(picture)
        status, answer = request("PATCH", resource(kind, item_id), key, body, content_type)
        time.sleep(SPACING)
        after = icon_of(kind, item_id, key)
        took = status in (200, 204) and after not in (None, before)
        print(f"{item_key} ({kind} {item_id}): PATCH {status}, icon {before} -> {after}{'' if took else '  FAILED'}")
        if not took:
            print(f"  answer: {answer}")
            failed.append(item_key)
        log[item_key] = {"Kind": kind, "Id": item_id, "Before": before, "After": after, "Ok": took}
        log_path.write_text(json.dumps(log, indent=1), encoding="utf-8")
        time.sleep(SPACING)
    print(f"{len(todo) - len(failed)} of {len(todo)} done" + (f"; failed: {', '.join(failed)}" if failed else ""))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
