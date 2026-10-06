# Builds a god in Blender from its shapes file (zeus.py and so on). Run inside Blender:
#   import sys; sys.path.insert(0, r"<repo>\art\gods"); import build; build.hi("zeus")
# Steps, each its own function so they can be rerun one at a time: hi (dense coloured mesh), low (decimated, UVs,
# baked texture), rig (armature and weights), then the walk and run in gait.py.
import importlib
import time

import bmesh
import bpy
import numpy as np

import sdf


def _module(god):
    importlib.reload(sdf)
    mod = importlib.import_module(god)
    return importlib.reload(mod)


def _replace(name, mesh):
    old = bpy.data.objects.get(name)
    if old is not None:
        bpy.data.objects.remove(old, do_unlink=True)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _vertex_color_material(name):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    for n in list(nodes):
        nodes.remove(n)
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    attr = nodes.new("ShaderNodeVertexColor")
    attr.layer_name = "Col"
    links.new(attr.outputs[0], bsdf.inputs[0])
    links.new(bsdf.outputs[0], out.inputs[0])
    bsdf.inputs["Roughness"].default_value = 0.65
    return mat


def hi(god, h=0.04, bounds=None, name=None):
    """The dense mesh: every shape merged, meshed, coloured. Returns (object, shapes). bounds: only that box (a
    close look at the head at a finer h)."""
    t0 = time.time()
    mod = _module(god)
    J = mod.joints()
    prims = mod.shapes(J)
    lo, hi_ = bounds or mod.BOUNDS
    D, origin, _ = sdf.evaluate_grid(prims, lo, hi_, h)
    t1 = time.time()
    verts, quads = sdf.surface_nets(D, origin, h)
    del D
    verts = sdf.project(prims, verts, h)
    t2 = time.time()
    who = sdf.winners(prims, verts)
    cols = sdf.colors(prims, verts, who)

    name = name or god.capitalize() + "_HI"
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts.tolist(), [], quads.tolist())
    mesh.validate()
    attr = mesh.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    lin = np.where(cols <= 0.04045, cols / 12.92, ((cols + 0.055) / 1.055) ** 2.4)
    rgba = np.concatenate([lin, np.ones((len(cols), 1))], axis=1).astype(np.float32)
    attr.data.foreach_set("color", rgba.ravel())
    mesh.shade_smooth()
    mesh.materials.append(_vertex_color_material("GodVertexColor"))
    obj = _replace(name, mesh)
    print(f"{god}: {len(prims)} shapes, grid {time.time() - t0:.1f}s total (field {t1 - t0:.1f}s, mesh "
          f"{t2 - t1:.1f}s), {len(verts)} verts, {len(quads)} quads")
    return obj, prims


def _mesh_arrays(obj):
    me = obj.data
    me.calc_loop_triangles()
    co = np.zeros(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    tris = np.zeros(len(me.loop_triangles) * 3, np.int64)
    me.loop_triangles.foreach_get("vertices", tris)
    loops = np.zeros(len(me.loop_triangles) * 3, np.int64)
    me.loop_triangles.foreach_get("loops", loops)
    return co, tris.reshape(-1, 3), loops.reshape(-1, 3)


def _select_only(obj):
    bpy.context.view_layer.objects.active = obj
    for o in bpy.context.selected_objects:
        o.select_set(False)
    obj.select_set(True)


def low(god, target=6000):
    """Decimates the dense mesh to about `target` triangles and unwraps it (paint() then paints it)."""
    t0 = time.time()
    mod = _module(god)
    src = bpy.data.objects[god.capitalize() + "_HI"]
    name = god.capitalize()
    mesh = src.data.copy()
    mesh.name = name
    obj = _replace(name, mesh)
    for a in list(mesh.color_attributes):
        mesh.color_attributes.remove(a)
    _select_only(obj)
    tris_now = sum(len(p.vertices) - 2 for p in mesh.polygons)
    # The face and fists keep more triangles: they're where a blocky silhouette shows.
    keep = obj.vertex_groups.new(name="Keep")
    co = np.zeros(len(mesh.vertices) * 3)
    mesh.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    w = np.zeros(len(co))
    spots = mod.detail(mod.joints()) if hasattr(mod, "detail") else []
    for centre, radius, weight in spots:
        d = np.linalg.norm(co - np.asarray(centre), axis=1)
        w = np.maximum(w, weight * np.clip(1.5 - d / radius, 0, 1))
    for n in np.nonzero(w > 0)[0]:
        keep.add([int(n)], float(w[n]), "REPLACE")
    dec = obj.modifiers.new("Decimate", "DECIMATE")
    dec.ratio = target / tris_now
    dec.use_collapse_triangulate = True
    dec.vertex_group = keep.name
    dec.invert_vertex_group = True  # a vertex group's weight marks what to decimate; inverted, it marks what to keep
    dec.vertex_group_factor = getattr(mod, "DETAIL_FACTOR", 8.0)
    bpy.ops.object.modifier_apply(modifier=dec.name)
    if obj.vertex_groups.get("Keep"):
        obj.vertex_groups.remove(obj.vertex_groups["Keep"])
    # Shade like the dense mesh: its normals on the low mesh's corners.
    src.hide_viewport = False
    tr = obj.modifiers.new("Normals", "DATA_TRANSFER")
    tr.object = src
    tr.use_loop_data = True
    tr.data_types_loops = {"CUSTOM_NORMAL"}
    tr.loop_mapping = "POLYINTERP_NEAREST"
    bpy.ops.object.modifier_apply(modifier=tr.name)
    src.hide_viewport = True
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.quads_convert_to_tris()
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.004, area_weight=0.0, scale_to_bounds=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    _favour_face(obj, getattr(mod, "FACE_ABOVE", None), getattr(mod, "FACE_UV_SCALE", 1.0))
    co, tris, _ = _mesh_arrays(obj)
    print(f"{name}: {len(tris)} triangles, {len(co)} verts ({time.time() - t0:.1f}s)")
    return obj


def paint(god, size=1024, ao=True):
    """Paints the low mesh's texture straight from the shapes: each texel's point is pulled onto the true surface and
    coloured by the shape there, so colour edges are exact; soft occlusion darkens the creases."""
    t0 = time.time()
    mod = _module(god)
    prims = mod.shapes(mod.joints())
    name = god.capitalize()
    obj = bpy.data.objects[name]
    mesh = obj.data
    co, tris, loops = _mesh_arrays(obj)
    uv = np.zeros(len(mesh.uv_layers.active.data) * 2)
    mesh.uv_layers.active.data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    pix, tri_id, bary = _rasterize(uv[loops] * size, size)
    P = np.einsum("nk,nkj->nj", bary, co[tris[tri_id]])
    P = sdf.project(prims, P, 0.06, steps=5)
    who = _despeckle(sdf.winners(prims, P), pix, size)
    col = sdf.colors(prims, P, who)
    if ao:
        col *= _occlusion(prims, P)[:, None]
    img = np.zeros((size * size, 4))
    filled = np.zeros(size * size, bool)
    img[pix, :3] = col
    img[pix, 3] = 1
    filled[pix] = True
    img = _dilate(img.reshape(size, size, 4), filled.reshape(size, size), 6)
    image = bpy.data.images.get(name + "Color") or bpy.data.images.new(name + "Color", size, size)
    if image.size[0] != size:
        image.scale(size, size)
    image.pixels.foreach_set(img.ravel().astype(np.float32))
    image.update()
    mat = bpy.data.materials.get(name + "Mat") or bpy.data.materials.new(name + "Mat")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    for n in list(nodes):
        nodes.remove(n)
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    mat.node_tree.links.new(tex.outputs[0], bsdf.inputs[0])
    mat.node_tree.links.new(bsdf.outputs[0], out.inputs[0])
    bsdf.inputs["Roughness"].default_value = 0.7
    mesh.materials.clear()
    mesh.materials.append(mat)
    print(f"{name}: texture {size} painted, {len(pix)} texels ({time.time() - t0:.1f}s)")
    return image


def rig(god):
    """An armature from the god's joints (a Root on the ground, then its BONES), and the low mesh skinned to it: each
    vertex follows the shapes that form the surface there, blended across joints; the skirt hangs from the hips and
    follows each thigh more towards the hem."""
    mod = _module(god)
    J = mod.joints()
    prims = mod.shapes(J)
    name = god.capitalize()
    obj = bpy.data.objects[name]
    rig_name = name + "_Rig"
    old = bpy.data.objects.get(rig_name)
    if old is not None:
        bpy.data.objects.remove(old, do_unlink=True)
    arm = bpy.data.armatures.new(rig_name)
    rig_obj = bpy.data.objects.new(rig_name, arm)
    bpy.context.scene.collection.objects.link(rig_obj)
    _select_only(rig_obj)
    bpy.ops.object.mode_set(mode="EDIT")
    root = arm.edit_bones.new("Root")
    root.head = (0, 0, 0)
    root.tail = (0, 0, 1.0)
    for bone, (head, tail, parent) in mod.BONES.items():
        eb = arm.edit_bones.new(bone)
        eb.head = tuple(J[head])
        eb.tail = tuple(J[tail])
        eb.parent = arm.edit_bones[parent] if parent else root
        eb.use_connect = False
    # Local Z faces forward (or up, for bones that point forward), so every bone bends the same way round.
    for eb in arm.edit_bones:
        d = (eb.tail - eb.head).normalized()
        eb.align_roll((0, 0, 1) if abs(d.y) > 0.7 else (0, -1, 0))
    bpy.ops.object.mode_set(mode="OBJECT")

    co = np.zeros(len(obj.data.vertices) * 3)
    obj.data.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    who = sdf.winners(prims, co)
    names, W = sdf.weights(prims, co, who, ["Root"] + list(mod.BONES))
    if hasattr(mod, "reweight"):
        W = mod.reweight(prims, co, who, names, W)
    # Roblox skins a vertex to at most four bones: keep each vertex's four strongest.
    weakest = np.argsort(-W, axis=1)[:, 4:]
    np.put_along_axis(W, weakest, 0.0, axis=1)
    W /= np.maximum(W.sum(axis=1, keepdims=True), 1e-9)
    obj.vertex_groups.clear()
    for b, bone in enumerate(names):
        vg = obj.vertex_groups.new(name=bone)
        for n in np.nonzero(W[:, b] > 1e-4)[0]:
            vg.add([int(n)], float(W[n, b]), "REPLACE")
    for m in list(obj.modifiers):
        if m.type == "ARMATURE":
            obj.modifiers.remove(m)
    mod_arm = obj.modifiers.new("Armature", "ARMATURE")
    mod_arm.object = rig_obj
    obj.parent = rig_obj
    print(f"{rig_name}: {len(arm.bones)} bones; {len(co)} vertices weighted, at most "
          f"{int((W > 1e-4).sum(axis=1).max())} bones each")
    return rig_obj


def _favour_face(obj, face_z, scale):
    """Gives the head's UV islands more of the texture (the face's details are painted), then repacks."""
    if face_z is None or scale == 1.0:
        return
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    uv_layer = bm.loops.layers.uv.active
    # Islands: faces joined across edges whose two sides share UVs.
    bm.faces.ensure_lookup_table()
    parent = list(range(len(bm.faces)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for e in bm.edges:
        if len(e.link_faces) != 2:
            continue
        f, g = e.link_faces
        same = True
        for v in e.verts:
            uv_f = next(lp[uv_layer].uv for lp in f.loops if lp.vert == v)
            uv_g = next(lp[uv_layer].uv for lp in g.loops if lp.vert == v)
            if (uv_f - uv_g).length > 1e-6:
                same = False
                break
        if same:
            parent[find(f.index)] = find(g.index)
    islands = {}
    for f in bm.faces:
        islands.setdefault(find(f.index), []).append(f)
    for faces in islands.values():
        mean_z = sum(f.calc_center_median().z for f in faces) / len(faces)
        if mean_z <= face_z:
            continue
        pts = [lp[uv_layer].uv.copy() for f in faces for lp in f.loops]
        cx = sum(p.x for p in pts) / len(pts)
        cy = sum(p.y for p in pts) / len(pts)
        for f in faces:
            for lp in f.loops:
                lp[uv_layer].uv.x = cx + (lp[uv_layer].uv.x - cx) * scale
                lp[uv_layer].uv.y = cy + (lp[uv_layer].uv.y - cy) * scale
    bm.to_mesh(me)
    bm.free()
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(rotate=True, margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")


def _rasterize(T, size):
    """Texels whose centres fall in each UV triangle (T: (n, 3, 2) in pixels). Returns flat pixel index, triangle
    and barycentric weights. Edges are widened a little so neighbouring triangles leave no gaps."""
    pix, tri, bary = [], [], []
    for n, t in enumerate(T):
        x0, y0 = np.floor(t.min(axis=0)).astype(int)
        x1, y1 = np.ceil(t.max(axis=0)).astype(int)
        x0, y0 = max(x0, 0), max(y0, 0)
        x1, y1 = min(x1, size - 1), min(y1, size - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        p = np.stack([xs.ravel(), ys.ravel()], axis=1)
        a, b, c = t
        v0, v1 = b - a, c - a
        den = v0[0] * v1[1] - v1[0] * v0[1]
        if abs(den) < 1e-12:
            continue
        w = p - a
        l1 = (w[:, 0] * v1[1] - v1[0] * w[:, 1]) / den
        l2 = (v0[0] * w[:, 1] - w[:, 0] * v0[1]) / den
        l0 = 1 - l1 - l2
        eps = 0.6 / max(np.sqrt(abs(den)), 1e-6)
        inside = (l0 >= -eps) & (l1 >= -eps) & (l2 >= -eps)
        if not inside.any():
            continue
        L = np.clip(np.stack([l0, l1, l2], axis=1)[inside], 0, 1)
        L /= L.sum(axis=1, keepdims=True)
        q = p[inside].astype(int)
        pix.append(q[:, 1] * size + q[:, 0])
        tri.append(np.full(len(q), n))
        bary.append(L)
    pix = np.concatenate(pix)
    tri = np.concatenate(tri)
    bary = np.concatenate(bary)
    # A texel two triangles both claim keeps one of them: either describes the same bit of surface.
    _, keep = np.unique(pix, return_index=True)
    return pix[keep], tri[keep], bary[keep]


def _despeckle(who, pix, size, passes=2):
    """Where a big low-poly triangle spans a crease (moustache over cheek), neighbouring texels land on different
    shapes and speckle. A texel with at most one neighbour of its own shape takes the shape most of its neighbours
    have (five of eight or more)."""
    ids = np.full(size * size, -1)
    for _ in range(passes):
        ids[:] = -1
        ids[pix] = who
        grid = ids.reshape(size, size)
        neigh = np.stack([np.roll(np.roll(grid, dy, 0), dx, 1).ravel()[pix]
                          for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx])
        same = (neigh == who).sum(axis=0)
        counts = (neigh[:, None, :] == neigh[None, :, :]).sum(axis=1)
        counts[neigh < 0] = 0
        best = np.argmax(counts, axis=0)
        major = neigh[best, np.arange(len(pix))]
        swap = (same <= 1) & (counts[best, np.arange(len(pix))] >= 5)
        who = np.where(swap, major, who)
    return who


def _occlusion(prims, P, step=0.07, samples=5, strength=0.9):
    """Soft darkening in creases (under the beard, round the belt, between the knuckles), from the shapes'
    distances: points along the normal that are closer to the surface than their height are occluded."""
    e = 0.01
    g = np.zeros_like(P)
    for axis in range(3):
        off = np.zeros(3)
        off[axis] = e
        g[:, axis] = sdf.evaluate_points(prims, P + off) - sdf.evaluate_points(prims, P - off)
    n = g / np.maximum(np.linalg.norm(g, axis=1, keepdims=True), 1e-9)
    occ = np.zeros(len(P))
    for i in range(1, samples + 1):
        h = step * i
        d = sdf.evaluate_points(prims, P + n * h)
        occ += (h - np.minimum(d, h)) / (2.0 ** i)
    return np.clip(1.0 - strength * occ / step, 0.55, 1.0)


def _dilate(img, filled, steps):
    """Bleeds the islands' edges outwards so texture filtering doesn't pull in the background."""
    for _ in range(steps):
        acc = np.zeros_like(img)
        cnt = np.zeros(filled.shape)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            acc += np.roll(np.roll(img * filled[..., None], dy, axis=0), dx, axis=1)
            cnt += np.roll(np.roll(filled, dy, axis=0), dx, axis=1)
        grow = (~filled) & (cnt > 0)
        img[grow] = acc[grow] / cnt[grow][:, None]
        filled = filled | grow
    img[~filled] = (0.5, 0.5, 0.5, 1)
    img[..., 3] = 1
    return img
