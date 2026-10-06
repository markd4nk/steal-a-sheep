# Signed-distance modelling for the god models, run inside Blender (numpy only).
#
# A god is a list of shapes (Prim): each has a distance function, the bone it moves with and a colour. They're merged
# into one closed surface (smooth where a shape asks for it), meshed with surface nets, and the mesh's vertices get
# their colours and bone weights from the shapes that form the surface there. One surface means one skinned mesh with
# no hidden layers, which keeps the triangle budget on what shows.
import math

import numpy as np

BIG = 1.0e3


def rot(x=0.0, y=0.0, z=0.0):
    """World-from-local rotation from XYZ euler degrees."""
    x, y, z = math.radians(x), math.radians(y), math.radians(z)
    cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return rz @ ry @ rx


def look_rot(axis):
    """A rotation whose local +Z points along axis."""
    z = np.asarray(axis, float)
    z = z / np.linalg.norm(z)
    up = np.array([0.0, 0.0, 1.0]) if abs(z[2]) < 0.9 else np.array([1.0, 0.0, 0.0])
    x = np.cross(up, z)
    x /= np.linalg.norm(x)
    y = np.cross(z, x)
    return np.stack([x, y, z], axis=1)


def smin(a, b, k):
    if k <= 0:
        return np.minimum(a, b)
    h = np.maximum(k - np.abs(a - b), 0.0) / k
    return np.minimum(a, b) - h * h * k * 0.25


def smax(a, b, k):
    return -smin(-a, -b, k)


def _len(v):
    return np.sqrt(np.einsum("ij,ij->i", v, v))


# Shape distance functions in local coordinates: q is (N, 3).


def f_sphere(r):
    return lambda q: _len(q) - r


def f_ellipsoid(r):
    r = np.asarray(r, float)

    def f(q):
        k0 = _len(q / r)
        k1 = _len(q / (r * r))
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)

    return f


def f_box(half, round_=0.0):
    half = np.asarray(half, float)

    def f(q):
        d = np.abs(q) - half + round_
        outside = _len(np.maximum(d, 0.0))
        inside = np.minimum(np.max(d, axis=1), 0.0)
        return outside + inside - round_

    return f


def f_torus(major, minor):
    """Ring around local Z."""

    def f(q):
        a = np.sqrt(q[:, 0] ** 2 + q[:, 1] ** 2) - major
        return np.sqrt(a * a + q[:, 2] ** 2) - minor

    return f


def f_cylinder(radius, half_height, round_=0.0):
    """Capped cylinder along local Z."""

    def f(q):
        dx = np.sqrt(q[:, 0] ** 2 + q[:, 1] ** 2) - radius + round_
        dy = np.abs(q[:, 2]) - half_height + round_
        outside = np.sqrt(np.maximum(dx, 0) ** 2 + np.maximum(dy, 0) ** 2)
        return outside + np.minimum(np.maximum(dx, dy), 0.0) - round_

    return f


def f_roundcone(a, b, r1, r2):
    """Tapered capsule from a (radius r1) to b (radius r2), in the same frame as q."""
    a = np.asarray(a, float)
    b = np.asarray(b, float)
    ba = b - a
    l2 = float(ba @ ba)
    rr = r1 - r2
    a2 = l2 - rr * rr
    il2 = 1.0 / l2

    def f(q):
        pa = q - a
        y = pa @ ba
        z = y - l2
        w = pa * l2 - np.outer(y, ba)
        x2 = np.einsum("ij,ij->i", w, w)
        y2 = y * y * l2
        z2 = z * z * l2
        k = np.sign(rr) * rr * rr * x2
        d_mid = (np.sqrt(np.maximum(x2 * a2 * il2, 0.0)) + y * rr) * il2 - r1
        d_b = np.sqrt(x2 + z2) * il2 - r2
        d_a = np.sqrt(x2 + y2) * il2 - r1
        return np.where(np.sign(z) * a2 * z2 > k, d_b, np.where(np.sign(y) * a2 * y2 < k, d_a, d_mid))

    return f


class Prim:
    """One shape. k: smooth-merge radius with what came before. sub: carve it out instead. color: (r, g, b) 0-255 or
    a function (points (N, 3)) -> (N, 3) colours. bone: the bone it moves with. reach: how far its bone weight spreads
    onto neighbouring shapes' surfaces (bigger at joints)."""

    def __init__(self, f, center=(0, 0, 0), R=None, scale=None, radius=1.0, k=0.0, sub=False, color=None,
                 bone=None, reach=0.12, disp=None, disp_amp=0.0, name="", bias=0.0, clip=None, world=False,
                 bounds=None):
        self.f = f
        self.c = np.asarray(center, float)
        self.R = None if R is None else np.asarray(R, float)
        self.s = None if scale is None else np.asarray(scale, float)
        self.k = k
        self.sub = sub
        self.color = color
        self.bone = bone
        self.reach = reach
        self.disp = disp
        self.name = name
        self.bias = bias
        self.clip = clip  # (f_world, k): intersected with this shape
        self.world = world  # f takes world points
        margin = radius + disp_amp + k
        self.lo = self.c - margin
        self.hi = self.c + margin
        if bounds is not None:
            self.lo = np.asarray(bounds[0], float) - disp_amp - k
            self.hi = np.asarray(bounds[1], float) + disp_amp + k

    def local(self, P):
        if self.world:
            return P
        q = P - self.c
        if self.R is not None:
            q = q @ self.R
        if self.s is not None:
            q = q / self.s
        return q

    def eval(self, P):
        d = self.f(self.local(P))
        if self.s is not None:
            d = d * float(np.min(self.s))
        if self.disp is not None:
            d = d + self.disp(P)
        if self.clip is not None:
            fc, kc = self.clip
            d = smax(d, fc(P), kc)
        return d


def sphere(c, r, **kw):
    return Prim(f_sphere(r), c, radius=r, **kw)


def ellipsoid(c, r, R=None, **kw):
    return Prim(f_ellipsoid(r), c, R=R, radius=float(np.max(r)), **kw)


def box(c, half, R=None, round_=0.0, **kw):
    return Prim(f_box(half, round_), c, R=R, radius=float(np.linalg.norm(half)), **kw)


def torus(c, major, minor, R=None, **kw):
    return Prim(f_torus(major, minor), c, R=R, radius=major + minor, **kw)


def cylinder(c, radius, half_height, R=None, round_=0.0, **kw):
    return Prim(f_cylinder(radius, half_height, round_), c, R=R, radius=math.hypot(radius, half_height), **kw)


def limb(a, b, r1, r2, scale=None, **kw):
    """Tapered capsule between two world points; scale squashes its cross-section (local x, y) around the axis.
    Careful: for a limb along Z, local x is world Y and local y is world X (look_rot)."""
    a = np.asarray(a, float)
    b = np.asarray(b, float)
    c = (a + b) / 2
    length = float(np.linalg.norm(b - a))
    R = look_rot(b - a)
    f = f_roundcone((0, 0, -length / 2), (0, 0, length / 2), r1, r2)
    s = None if scale is None else np.array([scale[0], scale[1], 1.0])
    return Prim(f, c, R=R, scale=s, radius=length / 2 + max(r1, r2), **kw)


def plane_f(point, normal):
    """World-space half-space, negative on the side the normal points away from."""
    n = np.asarray(normal, float)
    n = n / np.linalg.norm(n)
    p0 = np.asarray(point, float)
    return lambda P: (P - p0) @ n


# Building the surface.


def evaluate_grid(prims, lo, hi, h):
    lo = np.asarray(lo, float)
    hi = np.asarray(hi, float)
    n = np.ceil((hi - lo) / h).astype(int) + 1
    D = np.full(tuple(n), BIG, np.float32)
    for p in prims:
        plo = np.floor((p.lo - 2 * h - lo) / h).astype(int)
        phi = np.ceil((p.hi + 2 * h - lo) / h).astype(int) + 1
        plo = np.clip(plo, 0, n)
        phi = np.clip(phi, 0, n)
        if np.any(phi <= plo):
            continue
        xs = lo[0] + h * np.arange(plo[0], phi[0])
        ys = lo[1] + h * np.arange(plo[1], phi[1])
        zs = lo[2] + h * np.arange(plo[2], phi[2])
        X, Y, Z = np.meshgrid(xs, ys, zs, indexing="ij")
        P = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
        d = p.eval(P).reshape(X.shape).astype(np.float32)
        view = D[plo[0]:phi[0], plo[1]:phi[1], plo[2]:phi[2]]
        if p.sub:
            view[...] = smax(view, -d, p.k)
        else:
            view[...] = smin(view, d, p.k)
    return D, lo, n


def evaluate_points(prims, P):
    D = np.full(len(P), BIG)
    for p in prims:
        inside = np.all((P >= p.lo - 1e-6) & (P <= p.hi + 1e-6), axis=1)
        if not inside.any():
            continue
        idx = np.nonzero(inside)[0]
        d = p.eval(P[idx])
        if p.sub:
            D[idx] = smax(D[idx], -d, p.k)
        else:
            D[idx] = smin(D[idx], d, p.k)
    return D


_CORNERS = np.array([[i, j, k] for k in (0, 1) for j in (0, 1) for i in (0, 1)])
_EDGES = [(a, b) for a in range(8) for b in range(a + 1, 8) if np.abs(_CORNERS[a] - _CORNERS[b]).sum() == 1]


def surface_nets(D, lo, h):
    nx, ny, nz = D.shape
    inside = D < 0
    vals = [D[i:nx - 1 + i, j:ny - 1 + j, k:nz - 1 + k] for i, j, k in _CORNERS]
    mn = np.minimum.reduce(vals)
    mx = np.maximum.reduce(vals)
    ia, ja, ka = np.nonzero((mn < 0) & (mx >= 0))
    del vals, mn, mx
    m = len(ia)
    acc = np.zeros((m, 3))
    cnt = np.zeros(m)
    corner = [D[ia + i, ja + j, ka + k].astype(float) for i, j, k in _CORNERS]
    for a, b in _EDGES:
        fa, fb = corner[a], corner[b]
        mask = (fa < 0) != (fb < 0)
        t = np.where(mask, fa / np.where(mask, fa - fb, 1.0), 0.0)
        pos = _CORNERS[a] + t[:, None] * (_CORNERS[b] - _CORNERS[a])
        acc += np.where(mask[:, None], pos, 0.0)
        cnt += mask
    verts = lo + h * (np.stack([ia, ja, ka], axis=1) + acc / np.maximum(cnt, 1)[:, None])
    index = np.full((nx - 1, ny - 1, nz - 1), -1, np.int64)
    index[ia, ja, ka] = np.arange(m)

    quads = []
    # x edges: cells around (i, j, k)-(i+1, j, k) in the yz plane.
    s0 = inside[:-1, 1:-1, 1:-1]
    s1 = inside[1:, 1:-1, 1:-1]
    i, j, k = np.nonzero(s0 != s1)
    j, k = j + 1, k + 1
    flip = inside[i, j, k]
    q = np.stack([index[i, j - 1, k - 1], index[i, j, k - 1], index[i, j, k], index[i, j - 1, k]], axis=1)
    quads.append(np.where(flip[:, None], q, q[:, ::-1]))
    # y edges: (z, x) plane.
    s0 = inside[1:-1, :-1, 1:-1]
    s1 = inside[1:-1, 1:, 1:-1]
    i, j, k = np.nonzero(s0 != s1)
    i, k = i + 1, k + 1
    flip = inside[i, j, k]
    q = np.stack([index[i - 1, j, k - 1], index[i - 1, j, k], index[i, j, k], index[i, j, k - 1]], axis=1)
    quads.append(np.where(flip[:, None], q, q[:, ::-1]))
    # z edges: (x, y) plane.
    s0 = inside[1:-1, 1:-1, :-1]
    s1 = inside[1:-1, 1:-1, 1:]
    i, j, k = np.nonzero(s0 != s1)
    i, j = i + 1, j + 1
    flip = inside[i, j, k]
    q = np.stack([index[i - 1, j - 1, k], index[i, j - 1, k], index[i, j, k], index[i - 1, j, k]], axis=1)
    quads.append(np.where(flip[:, None], q, q[:, ::-1]))
    quads = np.concatenate(quads)
    quads = quads[np.all(quads >= 0, axis=1)]
    return verts, quads


def project(prims, verts, h, steps=2):
    """Pull surface-net vertices onto the true surface (Newton steps along the gradient)."""
    e = h * 0.25
    for _ in range(steps):
        d = evaluate_points(prims, verts)
        g = np.zeros_like(verts)
        for axis in range(3):
            off = np.zeros(3)
            off[axis] = e
            g[:, axis] = (evaluate_points(prims, verts + off) - evaluate_points(prims, verts - off)) / (2 * e)
        gl = np.einsum("ij,ij->i", g, g)
        step = np.where(gl > 1e-8, d / np.maximum(gl, 1e-8), 0.0)
        step = np.clip(step, -h, h)
        verts = verts - g * step[:, None]
    return verts


# Colours and weights from the shapes.


def winners(prims, P):
    """Index of the shape forming the surface at each point: the one whose distance matches the whole field's there
    (carving shapes included if they have a colour). Matching the field, not just being nearest, keeps a point a
    little inside the skirt the skirt's, not the thigh's under it."""
    field = evaluate_points(prims, P)
    best = np.full(len(P), np.inf)
    who = np.full(len(P), -1)
    for n, p in enumerate(prims):
        if p.sub and p.color is None:
            continue
        inside = np.all((P >= p.lo - 1e-6) & (P <= p.hi + 1e-6), axis=1)
        if not inside.any():
            continue
        idx = np.nonzero(inside)[0]
        d = p.eval(P[idx])
        d = np.abs((-d if p.sub else d) - field[idx]) - p.bias
        better = d < best[idx]
        best[idx[better]] = d[better]
        who[idx[better]] = n
    return who


def colors(prims, P, who):
    out = np.full((len(P), 3), 200.0)
    for n, p in enumerate(prims):
        sel = who == n
        if not sel.any() or p.color is None:
            continue
        if callable(p.color):
            out[sel] = p.color(P[sel])
        else:
            out[sel] = p.color
    return out / 255.0


def weights(prims, P, who, bones, top=4):
    """Per-vertex bone weights: the forming shape's bone, blended with nearby shapes' bones within their reach."""
    names = list(bones)
    W = np.zeros((len(P), len(names)))
    dist = np.full((len(prims), len(P)), np.inf)
    for n, p in enumerate(prims):
        if p.sub or p.bone is None:
            continue
        lo, hi = p.lo - p.reach * 3, p.hi + p.reach * 3
        inside = np.all((P >= lo) & (P <= hi), axis=1)
        if inside.any():
            idx = np.nonzero(inside)[0]
            dist[n, idx] = np.maximum(p.eval(P[idx]), 0.0)
    for n, p in enumerate(prims):
        if p.sub or p.bone is None:
            continue
        w = np.exp(-((dist[n] / p.reach) ** 2))
        W[:, names.index(p.bone)] += w
    own = np.array([prims[n].bone if n >= 0 else None for n in who], dtype=object)
    for b, name in enumerate(names):
        W[own == name, b] += 1e-3
    order = np.argsort(-W, axis=1)[:, :top]
    keep = np.zeros_like(W, bool)
    np.put_along_axis(keep, order, True, axis=1)
    W = np.where(keep, W, 0.0)
    W /= np.maximum(W.sum(axis=1, keepdims=True), 1e-9)
    return names, W
