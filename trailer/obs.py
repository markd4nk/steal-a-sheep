"""Drive OBS (31.x, obs-websocket 5) for trailer takes.

    python trailer/obs.py setup              scene "Trailer": Studio's window + Studio's own audio
    python trailer/obs.py frame L T R B W H  crop the window capture and size the canvas to the crop
    python trailer/obs.py still OUT.png      a still of what OBS sees, to check framing
    python trailer/obs.py start              start recording
    python trailer/obs.py stop NAME          stop and rename the take to NAME.mkv
    python trailer/obs.py take NAME SECONDS  start, wait, stop (run it in the background while the shot plays)

Footage goes to raw/ under %USERPROFILE%/Videos/<game name>Trailer (set it as the OBS profile's recording path,
outside OneDrive; TRAILER_DIR overrides the folder). The websocket password sits next to the footage in
.obs-ws-password.
"""

import base64
import os
import re
import sys
import time

import obsws_python as obs


def trailer_root() -> str:
    """%USERPROFILE%/Videos/<game name>Trailer, outside the repo and OneDrive: a shoot is gigabytes of takes.
    TRAILER_DIR overrides it; the name is GameConfig's Name without spaces."""
    if os.environ.get("TRAILER_DIR"):
        return os.environ["TRAILER_DIR"]
    config = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src", "shared", "Config", "GameConfig.luau")
    name = "Game"
    try:
        with open(config, encoding="utf-8") as f:
            found = re.search(r'Name\s*=\s*"([^"]+)"', f.read())
            if found:
                name = found.group(1)
    except OSError:
        pass
    return os.path.join(os.environ["USERPROFILE"], "Videos", name.replace(" ", "") + "Trailer")


ROOT = trailer_root()
RAW = os.path.join(ROOT, "raw")
SCENE = "Trailer"
VIDEO = "Studio"
AUDIO = "Studio audio"
STUDIO_EXE = "RobloxStudioBeta.exe"


def client() -> obs.ReqClient:
    with open(os.path.join(ROOT, ".obs-ws-password")) as f:
        password = f.read().strip()
    return obs.ReqClient(host="localhost", port=4455, password=password, timeout=10)


def input_names(c: obs.ReqClient) -> list[str]:
    return [i["inputName"] for i in c.get_input_list().inputs]


def pick_item(c: obs.ReqClient, name: str, prop: str, needle: str) -> str:
    items = c.get_input_properties_list_property_items(name, prop).property_items
    for item in items:
        if needle.lower() in item["itemValue"].lower():
            return item["itemValue"]
    raise SystemExit(f"no {prop} matching {needle!r} for {name}: {[i['itemName'] for i in items]}")


def setup() -> None:
    c = client()
    scenes = [s["sceneName"] for s in c.get_scene_list().scenes]
    if SCENE not in scenes:
        c.create_scene(SCENE)
    c.set_current_program_scene(SCENE)
    names = input_names(c)
    if VIDEO not in names:
        c.create_input(SCENE, VIDEO, "window_capture", {"method": 2, "cursor": False, "client_area": True}, True)
    window = pick_item(c, VIDEO, "window", STUDIO_EXE)
    # Match by executable so Studio's title changing (place name, playtest) doesn't lose the window.
    c.set_input_settings(VIDEO, {"window": window, "priority": 2, "method": 2, "cursor": False, "client_area": True}, True)
    if AUDIO not in names:
        c.create_input(SCENE, AUDIO, "wasapi_process_output_capture", {}, True)
    c.set_input_settings(AUDIO, {"window": pick_item(c, AUDIO, "window", STUDIO_EXE), "priority": 2}, True)
    # Only the game's sound: no system sounds, notifications or microphone.
    for name in input_names(c):
        if name not in (VIDEO, AUDIO):
            kind = c.get_input_settings(name).input_kind
            if "wasapi" in kind or "input_capture" in kind or "output_capture" in kind:
                c.set_input_mute(name, True)
    print("window:", window)
    print("inputs:", input_names(c))


def frame(left: int, top: int, right: int, bottom: int, width: int, height: int) -> None:
    c = client()
    c.set_video_settings(60, 1, width, height, width, height)
    item = c.get_scene_item_id(SCENE, VIDEO).scene_item_id
    c.set_scene_item_transform(
        SCENE,
        item,
        {
            "cropLeft": left,
            "cropTop": top,
            "cropRight": right,
            "cropBottom": bottom,
            "positionX": 0,
            "positionY": 0,
            "boundsType": "OBS_BOUNDS_STRETCH",
            "boundsWidth": width,
            "boundsHeight": height,
        },
    )
    print(c.get_video_settings().__dict__)


def still(out: str) -> None:
    c = client()
    data = c.get_source_screenshot(SCENE, "png", None, None, 100).image_data
    with open(out, "wb") as f:
        f.write(base64.b64decode(data.split(",", 1)[1]))
    print(out)


def start() -> None:
    c = client()
    if not c.get_record_status().output_active:
        c.start_record()
    print("recording", time.strftime("%H:%M:%S"))


def stop(name: str) -> str:
    c = client()
    path = c.stop_record().output_path
    # OBS finishes writing the file a moment after the request returns.
    for _ in range(50):
        try:
            target = os.path.join(RAW, f"{name}.mkv")
            if os.path.exists(target):
                os.remove(target)
            os.replace(path, target)
            print(target)
            return target
        except PermissionError:
            time.sleep(0.2)
    raise SystemExit(f"couldn't rename {path}")


def take(name: str, seconds: float) -> None:
    start()
    time.sleep(seconds)
    stop(name)


if __name__ == "__main__":
    command, args = sys.argv[1], sys.argv[2:]
    if command == "setup":
        setup()
    elif command == "frame":
        frame(*map(int, args))
    elif command == "still":
        still(args[0])
    elif command == "start":
        start()
    elif command == "stop":
        stop(args[0])
    elif command == "take":
        take(args[0], float(args[1]))
    else:
        raise SystemExit(__doc__)
