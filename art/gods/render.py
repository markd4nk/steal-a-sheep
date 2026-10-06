# Mock-up renders of a rigged god: the neon bolt in his fist (as the game's neon blocks), a floor, stills and a
# walk-then-run clip. Only for showing the user; the game gets the mesh, rig and texture.
import glob
import math
import os
import shutil
import subprocess

import bpy
from mathutils import Matrix, Quaternion, Vector

import gait

BOLT = [(0.6, 2.3), (-0.35, 0.25), (0.5, 0.25), (-0.55, -2.3)]  # the game's neon bolt, 4.6 tall at scale 1
BOLT_WIDTHS = [0.62, 0.55, 0.5]
BOLT_COLOR = (1.0, 0.76, 0.06, 1)  # 255, 226, 70 in linear
# Blender's own PATH may miss a winget ffmpeg.
FFMPEG = next(iter(glob.glob(os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg*\ffmpeg-*\bin\ffmpeg.exe"))), "ffmpeg")


def _emission(name, color, strength):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    for n in list(nodes):
        nodes.remove(n)
    out = nodes.new("ShaderNodeOutputMaterial")
    em = nodes.new("ShaderNodeEmission")
    em.inputs[0].default_value = color
    em.inputs[1].default_value = strength
    mat.node_tree.links.new(em.outputs[0], out.inputs[0])
    return mat


def _metal(name, color):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = 0.6
    bsdf.inputs["Roughness"].default_value = 0.35
    return mat


def _linear(rgb):
    return tuple(((c / 255 + 0.055) / 1.055) ** 2.4 if c > 10 else c / 255 / 12.92 for c in rgb) + (1,)


def prop(rig, blocks, name="Prop", hand="RightHand"):
    """A symbol made of blocks, held in a fist: each block is (u, v, width, length, depth, turn, rgb, glows), u across
    the hand, v along it (up out of the fist), turn in degrees. Glowing blocks are the game's neon."""
    for o in [o for o in bpy.data.objects if o.name.startswith(name)]:
        bpy.data.objects.remove(o, do_unlink=True)
    rig.data.pose_position = "REST"
    bpy.context.view_layer.update()
    frame = rig.matrix_world @ rig.data.bones[hand].matrix_local  # Y along the hand, X across, Z forward
    for n, (u, v, w, h, d, turn, rgb, glows) in enumerate(blocks):
        bpy.ops.mesh.primitive_cube_add(size=1)
        o = bpy.context.active_object
        o.name = f"{name}{n + 1}"
        key = "%s_%d_%d_%d_%s" % (name, *rgb, glows)
        o.data.materials.append(_emission(key, _linear(rgb), 2.2) if glows else _metal(key, _linear(rgb)))
        local = (Matrix.Translation((u, v, 0.12)) @ Matrix.Rotation(math.radians(turn), 4, "Z")
                 @ Matrix.Diagonal((w, h, d, 1)))
        o.parent = rig
        o.parent_type = "BONE"
        o.parent_bone = hand
        o.matrix_world = frame @ local
    rig.data.pose_position = "POSE"
    bpy.context.view_layer.update()


def bolt_blocks(height=5.0, up=1.15):
    """Zeus's bolt: the game's neon zigzag, gripped low."""
    k = height / 4.6
    blocks = []
    for n, (a, b) in enumerate(zip(BOLT, BOLT[1:])):
        a = Vector((a[0] * k, a[1] * k))
        b = Vector((b[0] * k, b[1] * k))
        mid, d = (a + b) / 2, b - a
        blocks.append((mid.x, up + mid.y, BOLT_WIDTHS[n] * k, d.length + BOLT_WIDTHS[n] * 0.5, 0.45 * k,
                       -math.degrees(math.atan2(d.x, d.y)), (255, 226, 70), True))
    return blocks


def bolt(rig):
    prop(rig, bolt_blocks(), "Bolt")


def sceptre_blocks():
    """Hera's sceptre: a gold staff topped with a glowing peacock eye (teal, blue, a gold heart)."""
    gold, teal, blue = (246, 192, 48), (36, 190, 176), (40, 92, 220)
    eye = 4.45
    return [
        (0, 1.0, 0.2, 5.4, 0.2, 0, gold, False),
        (0, 3.75, 0.46, 0.18, 0.46, 0, gold, False),
        (0, eye, 1.0, 1.0, 0.22, 45, teal, True),
        (0, eye, 0.62, 0.62, 0.3, 45, blue, True),
        (0, eye, 0.28, 0.28, 0.38, 45, gold, True),
        (0, 5.3, 0.2, 0.32, 0.2, 0, gold, False),
    ]


def stage():
    """A floor of marble tiles, sky-blue world, sun and fill."""
    sc = bpy.context.scene
    floor = bpy.data.objects.get("Floor")
    if floor is None:
        bpy.ops.mesh.primitive_plane_add(size=400)
        floor = bpy.context.active_object
        floor.name = "Floor"
    mat = bpy.data.materials.get("FloorTiles") or bpy.data.materials.new("FloorTiles")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    for n in list(nodes):
        nodes.remove(n)
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    checker = nodes.new("ShaderNodeTexChecker")
    coord = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (40, 40, 40)
    checker.inputs["Color1"].default_value = (0.5, 0.48, 0.45, 1)
    checker.inputs["Color2"].default_value = (0.38, 0.36, 0.34, 1)
    links = mat.node_tree.links
    links.new(coord.outputs["UV"], mapping.inputs[0])
    links.new(mapping.outputs[0], checker.inputs[0])
    links.new(checker.outputs[0], bsdf.inputs[0])
    links.new(bsdf.outputs[0], out.inputs[0])
    bsdf.inputs["Roughness"].default_value = 0.8
    floor.data.materials.clear()
    floor.data.materials.append(mat)
    w = sc.world
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.42, 0.62, 0.9, 1)
    bg.inputs[1].default_value = 0.7
    try:
        sc.eevee.use_shadows = True
    except AttributeError:
        pass
    return floor


def aim(target, direction, distance, lens=50):
    cam = bpy.data.objects["Camera"]
    t = Vector(target)
    d = Vector(direction).normalized()
    cam.location = t + d * distance
    cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens
    bpy.context.scene.camera = cam


def still(path, size=(1200, 1200)):
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = size
    sc.render.image_settings.file_format = "PNG"
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def demo(rig, folder, walk_cycles=2, run_cycles=3, blend=8, size=(960, 720), start=0, stop=None, walk=None,
         run=None):
    """Walk then run across the floor, the camera following, rendered to PNGs (frames start to stop, so a long
    clip can go in several calls); encode() makes the mp4. Returns the clip's frame count."""
    os.makedirs(folder, exist_ok=True)
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = size
    sc.render.image_settings.file_format = "PNG"
    if rig.animation_data:
        rig.animation_data.action = None
    walk = walk or gait.walk
    run = run or gait.run
    walk_speed = gait.bake_speed(rig, walk, gait.WALK_FRAMES)
    run_speed = gait.bake_speed(rig, run, gait.RUN_FRAMES, gait.run_lift)
    walk_len = walk_cycles * gait.WALK_FRAMES
    total = walk_len + blend + run_cycles * gait.RUN_FRAMES
    phase, y = 0.0, 0.0
    root = rig.pose.bones["Root"]
    stop = total if stop is None else min(stop, total)
    for f in range(stop):
        t = min(max((f - walk_len) / blend, 0.0), 1.0)
        t = t * t * (3 - 2 * t)
        rate = (1 - t) / gait.WALK_FRAMES + t / gait.RUN_FRAMES
        speed = (1 - t) * walk_speed + t * run_speed
        if f >= start:
            a, b = walk(phase % 1.0), run(phase % 1.0)
            rot = {k: a.get(k, Quaternion()).slerp(b.get(k, Quaternion()), t) for k in set(a) | set(b)}
            gait.pose(rig, rot, t * gait.run_lift(phase % 1.0))
            rest = root.bone.matrix_local.to_quaternion()
            root.location = rest.inverted() @ Vector((0, -y, 0))
            bpy.context.view_layer.update()
            aim((0, -y - 0.5, 4.6), (1.0, -0.75, 0.1), 23, 50)
            sc.render.filepath = os.path.join(folder, f"f{f:04d}.png")
            bpy.ops.render.render(write_still=True)
        phase += rate
        y += speed
    return total


def encode(folder):
    mp4 = os.path.join(folder, "demo.mp4")
    ffmpeg = shutil.which("ffmpeg") or os.path.expandvars(FFMPEG)
    subprocess.run([ffmpeg, "-y", "-framerate", "24", "-i", os.path.join(folder, "f%04d.png"), "-c:v", "libx264",
                    "-pix_fmt", "yuv420p", "-crf", "20", mp4], check=True, capture_output=True)
    return mp4
