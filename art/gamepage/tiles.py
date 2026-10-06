# Renders bigger than Studio's viewport: one virtual camera is split into tiles, each tile is the same camera turned
# a little (a pure rotation about the same point), captured in Studio, and stitched back exactly (a rotation maps one
# pinhole image onto another with no parallax). Roblox's FieldOfView is the vertical field of view.
#
#   python tiles.py plan <plan.json> x y z tx ty tz fov W H [ss]   -> writes the tiles' CFrames and FOV
#   python tiles.py stitch <plan.json> <out.png> tile1.jpg tile2.jpg ...
import json
import math
import sys

import numpy as np
from PIL import Image

TILE_W, TILE_H = 1445, 650  # Studio's viewport in the screen captures


def look_at(eye, target):
    """Roblox's CFrame.lookAt with world up: columns are right, up, back (-look)."""
    f = np.asarray(target, float) - np.asarray(eye, float)
    f /= np.linalg.norm(f)
    r = np.cross(f, [0.0, 1.0, 0.0])
    r /= np.linalg.norm(r)
    u = np.cross(r, f)
    return np.stack([r, u, -f], axis=1)


def plan(eye, target, fov, W, H, ss=1.15, tile=(TILE_W, TILE_H)):
    w, h = tile
    Rv = look_at(eye, target)
    fv = (H / 2) / math.tan(math.radians(fov) / 2)
    ft = fv * ss
    Ft = 2 * math.degrees(math.atan((h / 2) / ft))
    cover_x = 0.82 * w / ft  # each tile's useful width on the virtual image plane, with overlap
    cover_y = 0.82 * h / ft
    nx = max(1, math.ceil((W / fv) / cover_x))
    ny = max(1, math.ceil((H / fv) / cover_y))
    tiles = []
    for j in range(ny):
        for i in range(nx):
            x = ((i + 0.5) / nx - 0.5) * (W / fv)
            y = (0.5 - (j + 0.5) / ny) * (H / fv)
            # Turn within the virtual camera's own frame (yaw, then pitch), so a tile keeps its roll: levelling each
            # tile to the world's up left wedges uncovered when the virtual camera pitched up steeply.
            yaw = math.atan(x)
            pitch = math.atan(y / math.sqrt(1 + x * x))
            cy, sy, cp, sp = math.cos(yaw), math.sin(yaw), math.cos(pitch), math.sin(pitch)
            ry = np.array([[cy, 0, -sy], [0, 1, 0], [sy, 0, cy]])
            rx = np.array([[1, 0, 0], [0, cp, -sp], [0, sp, cp]])
            Rt = Rv @ ry @ rx
            c = [*eye, *Rt[0], *Rt[1], *Rt[2]]  # CFrame.new(x, y, z, R00, R01, R02, R10, ...)
            tiles.append({"cframe": [float(v) for v in c], "R": Rt.tolist()})
    return {"eye": list(map(float, eye)), "Rv": Rv.tolist(), "fv": fv, "ft": ft, "fov_tile": Ft, "W": W, "H": H,
            "tile": [w, h], "tiles": tiles}


def _sample(img, u, v):
    """Bilinear sample of img (h, w, 3) at float pixel coords (pixel centres at +0.5)."""
    h, w = img.shape[:2]
    x = np.clip(u - 0.5, 0, w - 1.001)
    y = np.clip(v - 0.5, 0, h - 1.001)
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    fx, fy = (x - x0)[:, None], (y - y0)[:, None]
    a = img[y0, x0] * (1 - fx) + img[y0, x0 + 1] * fx
    b = img[y0 + 1, x0] * (1 - fx) + img[y0 + 1, x0 + 1] * fx
    return a * (1 - fy) + b * fy


def stitch(p, paths, out):
    W, H = p["W"], p["H"]
    w, h = p["tile"]
    fv, ft = p["fv"], p["ft"]
    Rv = np.array(p["Rv"])
    vs, us = np.mgrid[0:H, 0:W].astype(float)
    xn = (us + 0.5 - W / 2) / fv
    yn = (H / 2 - (vs + 0.5)) / fv
    D = np.stack([xn.ravel(), yn.ravel(), -np.ones(xn.size)], axis=1) @ Rv.T
    acc = np.zeros((D.shape[0], 3))
    wsum = np.zeros(D.shape[0])
    for t, path in zip(p["tiles"], paths):
        img = np.asarray(Image.open(path).convert("RGB"), float)
        assert img.shape[:2] == (h, w), (path, img.shape)
        L = D @ np.array(t["R"])  # into the tile's camera space
        front = L[:, 2] < -1e-6
        z = np.where(front, -L[:, 2], 1.0)
        u = w / 2 + ft * L[:, 0] / z
        v = h / 2 - ft * L[:, 1] / z
        edge = np.minimum.reduce([u, w - u, v, h - v])
        ok = front & (edge > 2)
        weight = np.where(ok, np.clip(edge / 60.0, 0, 1) ** 2, 0.0)
        idx = np.nonzero(ok)[0]
        acc[idx] += _sample(img, u[idx], v[idx]) * weight[idx, None]
        wsum[idx] += weight[idx]
    missing = int((wsum <= 0).sum())
    rgb = acc / np.maximum(wsum, 1e-9)[:, None]
    Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8).reshape(H, W, 3)).save(out)
    return missing


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "plan":
        path = sys.argv[2]
        x, y, z, tx, ty, tz, fov = map(float, sys.argv[3:10])
        W, H = int(sys.argv[10]), int(sys.argv[11])
        ss = float(sys.argv[12]) if len(sys.argv) > 12 else 1.15
        p = plan((x, y, z), (tx, ty, tz), fov, W, H, ss)
        json.dump(p, open(path, "w"))
        print(len(p["tiles"]), "tiles, fov", round(p["fov_tile"], 3))
        for t in p["tiles"]:
            print("{" + ", ".join(f"{v:.6f}" for v in t["cframe"]) + "}")
    elif cmd == "stitch":
        p = json.load(open(sys.argv[2]))
        missing = stitch(p, sys.argv[4:], sys.argv[3])
        print("missing pixels", missing)
