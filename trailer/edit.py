"""Cut the trailer from the takes in raw/ with ffmpeg.

    python trailer/edit.py trailer/cut.json            every variant in the cut list
    python trailer/edit.py trailer/cut.json page       one variant
    python trailer/edit.py sheet VIDEO [FPS]           a contact sheet of a video, to check it by eye
    python trailer/edit.py probe VIDEO                 duration, size and frame rate

The cut list (trailer/cut.json) names each clip's take, in and out points, speed, caption and transition, plus the
music and where it drops out. Each variant is a frame size and a caption set: "page" is the game page's video (Roblox
allows only plain gameplay captions and no lyrics or narration there), "tall" the 9:16 cut for TikTok and Shorts.
Clips are cut from the takes once per variant (cropped and scaled from the source, never from another variant), then
joined, the music mixed under the game's own sound, and the result loudness-normalised.
"""

import glob
import json
import os
import re
import shutil
import subprocess
import sys

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
WORK = os.path.join(ROOT, "work")
OUT = os.path.join(ROOT, "out")
FPS = 60
# The captions' outline colour and font; a cut list's "ink" and "font" (a file in Roblox's content/fonts) override them.
INK = "0x152A55"
FONT = "FredokaOne-Regular.ttf"


def ffmpeg_bin(name: str) -> str:
    found = shutil.which(name)
    if found:
        return found
    pattern = os.path.join(
        os.environ["LOCALAPPDATA"], "Microsoft", "WinGet", "Packages", "Gyan.FFmpeg*", "ffmpeg-*", "bin", name + ".exe"
    )
    matches = sorted(glob.glob(pattern))
    if not matches:
        raise SystemExit(f"{name} not found")
    return matches[-1]


FFMPEG = ffmpeg_bin("ffmpeg")
FFPROBE = ffmpeg_bin("ffprobe")


def font() -> str:
    """The captions' font, one of Roblox's own, copied next to the work files so drawtext needs no path escaping."""
    target = os.path.join(WORK, FONT)
    if not os.path.exists(target):
        pattern = os.path.join(os.environ["LOCALAPPDATA"], "Roblox", "Versions", "*", "content", "fonts", FONT)
        found = sorted(glob.glob(pattern))
        if not found:
            raise SystemExit(f"{FONT} isn't in Roblox's content/fonts")
        shutil.copy(found[-1], target)
    return FONT


def run(args: list[str]) -> None:
    result = subprocess.run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", *args], cwd=WORK)
    if result.returncode != 0:
        raise SystemExit(f"ffmpeg failed: {' '.join(args)}")


def probe(path: str) -> dict:
    out = subprocess.run(
        [FFPROBE, "-v", "error", "-show_entries", "format=duration:stream=codec_type,width,height,r_frame_rate", "-of", "json", path],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    info = json.loads(out)
    video = next(s for s in info["streams"] if s["codec_type"] == "video")
    return {
        "duration": float(info["format"]["duration"]),
        "width": video["width"],
        "height": video["height"],
        "fps": video["r_frame_rate"],
        "audio": any(s["codec_type"] == "audio" for s in info["streams"]),
    }


def text_file(name: str, text: str) -> str:
    path = os.path.join(WORK, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    return name


def fit(text: str, size: int, width: int) -> int:
    """Shrinks a font size until the longest line fits the frame's width (Fredoka One runs about 0.56 em a letter)."""
    longest = max(len(line) for line in text.splitlines() or [text]) or 1
    return int(min(size, width * 0.88 / (0.56 * longest)))


def fade_alpha(start: float, end: float, fade: float = 0.18) -> str:
    # Clipped to 0..1, so a caption carried across clips can start "already in" (a negative start).
    return (
        f"clip(if(lt(t,{start}),0,if(lt(t,{start + fade}),(t-{start})/{fade},"
        f"if(lt(t,{end - fade}),1,if(lt(t,{end}),({end}-t)/{fade},0)))),0,1)"
    )


def caption_filter(index: int, variant: str, caption: dict, width: int, height: int) -> str:
    tall = height > width
    size = fit(caption["text"], int(height * (0.052 if tall else 0.085) * caption.get("scale", 1)), width)
    border = max(3, size // 9)
    name = text_file(f"cap_{variant}_{index}.txt", caption["text"])
    start, end = caption.get("at", [0.25, 99])
    # Tall: the upper third, clear of TikTok's buttons and caption along the bottom and right. Wide: the lower third.
    y = f"h*{caption.get('y', 0.2 if tall else 0.74)}-text_h/2"
    return (
        f"drawtext=fontfile={font()}:textfile={name}:fontsize={size}:fontcolor=white:borderw={border}:"
        f"bordercolor={INK}:shadowcolor={INK}@0.6:shadowx=0:shadowy={border}:x=(w-text_w)/2:y={y}:"
        f"alpha='{fade_alpha(start, end)}'"
    )


def cut_clip(index: int, clip: dict, variant: str, spec: dict) -> tuple[str, float]:
    """One clip, cropped and scaled for this variant, captioned, at FPS, with stereo audio. Returns (file, seconds)."""
    width, height = spec["size"]
    src = os.path.join(RAW, clip["src"])
    info = probe(src)
    speed = clip.get("speed", 1.0)
    start, end = clip["in"], clip["out"]
    seconds = (end - start) / speed

    sw, sh = info["width"], info["height"]
    if width / height > sw / sh:
        cw, ch = sw, round(sw * height / width)
    else:
        cw, ch = round(sh * width / height), sh
    cw -= cw % 2
    ch -= ch % 2
    # Where the crop sits across the source (0 left .. 1 right): "x" for tall, "x_wide" for wide. Wide defaults to the
    # right edge, which leaves out the Roblox menu buttons in the top-left corner (they cannot be hidden in Studio).
    across = clip.get("x", 0.5) if height > width else clip.get("x_wide", 1.0)
    cx = round((sw - cw) * across)
    cy = round((sh - ch) * clip.get("y", 0.5))
    zoom = clip.get("zoom", 1.0)

    filters = [f"setpts=(PTS-STARTPTS)/{speed}"]
    if speed < 1 and clip.get("smooth", True):
        filters.append(f"minterpolate=fps={FPS}:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1")
    filters.append(f"fps={FPS}")
    filters.append(f"crop={cw}:{ch}:{cx}:{cy}")
    if zoom != 1.0:
        zw, zh = round(cw / zoom), round(ch / zoom)
        filters.append(f"crop={zw - zw % 2}:{zh - zh % 2}")
    filters.append(f"scale={width}:{height}:flags=lanczos,setsar=1")
    if clip.get("fade_in"):
        filters.append(f"fade=t=in:st=0:d={clip['fade_in']}")
    if clip.get("fade_out"):
        filters.append(f"fade=t=out:st={seconds - clip['fade_out']}:d={clip['fade_out']}")
    for c_index, caption in enumerate(clip.get("captions", {}).get(spec["captions"], [])):
        filters.append(caption_filter(index * 10 + c_index, variant, caption, width, height))
    filters.append("format=yuv420p")

    gain = clip.get("game_audio_db", 0)
    if info["audio"] and gain > -60:
        afilters = ["asetpts=PTS-STARTPTS"]
        if speed != 1:
            # Slowed sound drops in pitch with the picture, like a film slow-motion shot.
            afilters.append(f"asetrate=48000*{speed},aresample=48000")
        afilters += [f"volume={gain}dB", "aformat=sample_rates=48000:channel_layouts=stereo", f"apad=whole_dur={seconds}"]
        audio_args = ["-af", ",".join(afilters)]
        inputs = ["-ss", str(start), "-to", str(end), "-i", src]
        maps = ["-map", "0:v:0", "-map", "0:a:0"]
    else:
        audio_args = []
        inputs = ["-ss", str(start), "-to", str(end), "-i", src, "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo"]
        maps = ["-map", "0:v:0", "-map", "1:a:0"]

    out = f"seg_{variant}_{index:02d}.mkv"
    run(
        [
            *inputs,
            *maps,
            "-vf",
            ",".join(filters),
            *audio_args,
            "-t",
            f"{seconds:.3f}",
            "-c:v",
            "libx264",
            "-preset",
            "veryfast",
            "-crf",
            "10",
            "-c:a",
            "pcm_s16le",
            out,
        ]
    )
    return out, seconds


def title_card(variant: str, spec: dict, title: dict, background: str) -> tuple[str, float]:
    """The end card: the last frame of a clip, softened, with the game's name and a line under it."""
    width, height = spec["size"]
    tall = height > width
    seconds = title.get("seconds", 3.0)
    big = fit(title["text"], int(height * (0.085 if tall else 0.15)), width)
    small = fit(title.get("sub", {}).get(spec["captions"], "") or "x", int(big * 0.42), width)
    name = text_file(f"title_{variant}.txt", title["text"])
    sub_text = title.get("sub", {}).get(spec["captions"], "")
    filters = [
        "trim=start=0:end=1",
        "setpts=PTS-STARTPTS",
        f"tpad=stop_mode=clone:stop_duration={seconds}",
        "gblur=sigma=8",
        "eq=brightness=-0.06:saturation=1.15",
        f"drawtext=fontfile={font()}:textfile={name}:fontsize={big}:fontcolor=white:borderw={big // 9}:bordercolor={INK}:"
        f"shadowcolor={INK}@0.6:shadowy={big // 9}:x=(w-text_w)/2:y=h*0.42-text_h/2:alpha='{fade_alpha(0.15, seconds + 5, 0.3)}'",
    ]
    if sub_text:
        sub = text_file(f"title_sub_{variant}.txt", sub_text)
        filters.append(
            f"drawtext=fontfile={font()}:textfile={sub}:fontsize={small}:fontcolor=white:borderw={max(3, small // 8)}:"
            f"bordercolor={INK}:x=(w-text_w)/2:y=h*0.42+{big // 2}+{small // 2}:alpha='{fade_alpha(0.6, seconds + 5, 0.3)}'"
        )
    filters += [f"fps={FPS}", "format=yuv420p"]
    out = f"seg_{variant}_title.mkv"
    run(
        [
            "-sseof",
            "-0.5",
            "-i",
            background,
            "-f",
            "lavfi",
            "-i",
            "anullsrc=r=48000:cl=stereo",
            "-map",
            "0:v:0",
            "-map",
            "1:a:0",
            "-vf",
            ",".join(filters),
            "-t",
            f"{seconds:.3f}",
            "-c:v",
            "libx264",
            "-preset",
            "veryfast",
            "-crf",
            "10",
            "-c:a",
            "pcm_s16le",
            out,
        ]
    )
    return out, seconds


def join(segments: list[tuple[str, float, float]], out: str) -> float:
    """Joins (file, seconds, transition-into-this) segments: hard cuts, or crossfades where a transition is set."""
    inputs: list[str] = []
    for file, _, _ in segments:
        inputs += ["-i", file]
    # xfade needs matching timebases and aspect ratios; the title card's padding leaves its own.
    graph = [
        f"[{i}:v]fps={FPS},settb=1/{FPS},setsar=1,setpts=PTS-STARTPTS[n{i}];"
        f"[{i}:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[m{i}]"
        for i in range(len(segments))
    ]
    v, a = "[n0]", "[m0]"
    length = segments[0][1]
    for i in range(1, len(segments)):
        _, seconds, transition = segments[i]
        nv, na = f"[v{i}]", f"[a{i}]"
        if transition > 0:
            offset = length - transition
            # concat hands on a microsecond timebase; xfade wants both sides on the same one.
            graph.append(f"{v}settb=1/{FPS}[p{i}]")
            v = f"[p{i}]"
            graph.append(f"{v}[n{i}]xfade=transition={'fadeblack' if transition >= 0.4 else 'fade'}:duration={transition}:offset={offset:.3f}{nv}")
            graph.append(f"{a}[m{i}]acrossfade=d={transition}{na}")
            length += seconds - transition
        else:
            graph.append(f"{v}{a}[n{i}][m{i}]concat=n=2:v=1:a=1{nv}{na}")
            length += seconds
        v, a = nv, na
    run([*inputs, "-filter_complex", ";".join(graph), "-map", v, "-map", a, "-c:v", "libx264", "-preset", "veryfast", "-crf", "10", "-c:a", "pcm_s16le", out])
    return length


def music_filter(music: dict, length: float) -> str:
    parts = [f"atrim=start={music.get('start', 0)}", "asetpts=PTS-STARTPTS", f"volume={music.get('gain_db', -4)}dB"]
    for drop in music.get("duck", []):
        t0, t1, db = drop
        parts.append(f"volume=enable='between(t,{t0},{t1})':volume={db}dB")
    if music.get("fade_in"):
        parts.append(f"afade=t=in:st=0:d={music['fade_in']}")
    fade_out = music.get("fade_out", 1.5)
    parts.append(f"afade=t=out:st={length - fade_out}:d={fade_out}")
    parts.append(f"atrim=end={length}")
    return ",".join(parts)


def build(cut_path: str, only: str | None) -> None:
    global INK, FONT
    with open(cut_path, encoding="utf-8") as f:
        cut = json.load(f)
    INK = cut.get("ink", INK)
    FONT = cut.get("font", FONT)
    os.makedirs(WORK, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    for variant, spec in cut["variants"].items():
        if only and variant != only:
            continue
        clips = [c for c in cut["clips"] if variant not in c.get("skip", [])]
        segments: list[tuple[str, float, float]] = []
        for index, clip in enumerate(clips):
            file, seconds = cut_clip(index, clip, variant, spec)
            segments.append((file, seconds, clip.get("transition", 0)))
            print(f"  {variant} {index:02d} {clip['src']} {seconds:.2f}s")
        if cut.get("title"):
            file, seconds = title_card(variant, spec, cut["title"], segments[-1][0])
            segments.append((file, seconds, cut["title"].get("transition", 0.3)))
        joined = f"joined_{variant}.mkv"
        length = join(segments, joined)

        music = cut.get("music")
        final = os.path.join(OUT, f"{cut.get('name', 'trailer')}_{variant}.mp4")
        if music:
            graph = (
                f"[0:a]volume={cut.get('game_audio_db', 0)}dB[game];"
                f"[1:a]{music_filter(music, length)}[music];"
                "[game][music]amix=inputs=2:duration=first:normalize=0,loudnorm=I=-14:TP=-1.5:LRA=11[a]"
            )
            inputs = ["-i", joined, "-i", os.path.join(ROOT, music["file"])]
        else:
            graph = "[0:a]loudnorm=I=-14:TP=-1.5:LRA=11[a]"
            inputs = ["-i", joined]
        run(
            [
                *inputs,
                "-filter_complex",
                graph,
                "-map",
                "0:v",
                "-map",
                "[a]",
                "-c:v",
                "libx264",
                "-preset",
                "slow",
                "-crf",
                "17",
                "-pix_fmt",
                "yuv420p",
                "-c:a",
                "aac",
                "-b:a",
                "192k",
                "-ar",
                "48000",
                "-movflags",
                "+faststart",
                final,
            ]
        )
        print(f"{variant}: {final} ({length:.2f}s)")


def sheet(video: str, fps: float) -> None:
    info = probe(video)
    count = max(1, int(info["duration"] * fps))
    columns = 6
    rows = (count + columns - 1) // columns
    width = 320 if info["width"] >= info["height"] else 180
    out = os.path.join(WORK, os.path.splitext(os.path.basename(video))[0] + "_sheet.jpg")
    run(
        [
            "-i",
            video,
            "-vf",
            f"fps={fps},scale={width}:-2,drawtext=fontfile={font()}:text='%{{pts\\:hms}}':x=6:y=6:fontsize=16:fontcolor=white:borderw=2,tile={columns}x{rows}:padding=4",
            "-frames:v",
            "1",
            out,
        ]
    )
    print(out)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    if sys.argv[1] == "sheet":
        sheet(os.path.abspath(sys.argv[2]), float(sys.argv[3]) if len(sys.argv) > 3 else 2)
    elif sys.argv[1] == "probe":
        print(probe(os.path.abspath(sys.argv[2])))
    else:
        build(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
