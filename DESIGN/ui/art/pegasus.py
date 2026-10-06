"""Day 7's sheep for the Daily Gifts mock-up (mockups/daily-gifts.html): Shear a Sheep's fluffy sheep, built and
painted by its own art/icons/render_sheep_icons.py, in white with big feathered wings on its back and gold hooves. It
only reads that checkout (SHEAR_ART; it needs the face pictures in art/sheep/renders/fluffy/faces).

    blender -b --factory-startup -P DESIGN/ui/art/pegasus.py -- <out.png> [gold | white] [halo]

Writes a 1024 px PNG on a transparent background; assets/daily/pegasus-*.png are these, cropped.
"""

import math
import os
import pathlib
import sys

ROOT = pathlib.Path(os.environ.get("SHEAR_ART", r"C:\Users\markf\breed_render"))
sys.path.insert(0, str(ROOT / "art" / "icons"))
sys.path.insert(0, str(ROOT / "art" / "sheep"))
sys.dont_write_bytecode = True

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import render_sheep_icons as r  # noqa: E402
import build_sheep as sheep  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = pathlib.Path(args[0]) if args else pathlib.Path(__file__).resolve().parent / "pegasus.png"
VARIANT = args[1] if len(args) > 1 else "white"
HALO = "halo" in args

WHITE = (250, 250, 246)
FEATHER_TIP = {"white": (196, 226, 255), "gold": (255, 206, 72), "rainbow": None}[VARIANT]
GOLD = (255, 196, 40)
SPAN = 1.55  # how far each wing reaches out from its shoulder
HEIGHT = 1.45  # how high its arch rises
SWEEP = 0.5  # how far back it's swept (0 straight out to the side)


def ellipsoid(name, centre, axes, radii, colour, collection, kind="SmoothPlastic", segments=24):
    """A smooth UV sphere scaled to `radii` along the three unit vectors `axes`."""
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=segments // 2, radius=1.0)
    bm.to_mesh(mesh)
    bm.free()
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    a, b, c = (Vector(v).normalized() for v in axes)
    basis = Matrix((
        (a.x * radii[0], b.x * radii[1], c.x * radii[2], centre[0]),
        (a.y * radii[0], b.y * radii[1], c.y * radii[2], centre[1]),
        (a.z * radii[0], b.z * radii[1], c.z * radii[2], centre[2]),
        (0, 0, 0, 1),
    ))
    obj.matrix_world = basis
    r.paint(obj, colour, kind)
    return obj


def wing(sign, root, collection):
    """A cartoon wing raised from the back: a rounded leading edge arcing up and out, long feathers hanging from it
    (longest at the tip), a row of short coverts over their roots. `sign` +1 is the sheep's left (Blender +X)."""
    placed = []
    u = Vector((sign * 1.0, SWEEP, 0.0)).normalized()  # out, and back
    v = Vector((0.0, 0.22, 1.0)).normalized()  # up, a little back
    w = u.cross(v).normalized() * sign  # the wing's outer face
    root = Vector(root)

    def at(x, y, lift=0.0):
        return root + u * x + v * y + w * lift

    def edge(t):
        """The top of the wing: up from the shoulder in an arch, then out and down to the tip."""
        return (SPAN * t, HEIGHT * math.sin(math.pi * (0.18 + 0.62 * t)) - 0.1 * t)

    def feather(name, t, length, width, lift, angle, colour, drop=0.0):
        x, y = edge(t)
        d = u * math.cos(angle) + v * math.sin(angle)
        side = d.cross(w).normalized()
        centre = at(x, y - drop, lift) + d * (length * 0.5)
        placed.append(ellipsoid(name, centre, (d, side, w), (length * 0.5, width, 0.07), colour, collection))

    # The arch: overlapping puffs, thick at the shoulder.
    for index in range(10):
        t = index / 9
        x, y = edge(t)
        radius = 0.19 - 0.06 * t
        placed.append(ellipsoid(f"Arm{sign}{index}", at(x, y, 0.03), (u, v, w), (radius * 1.3, radius, radius * 0.8),
                                WHITE, collection))
    # Three rows hanging from the arch, longest at the tip, each row in front of the one behind it: long primaries
    # (the tinted ones), white secondaries, short round coverts.
    rows = [
        ("Primary", 8, (0.75, 1.55), 0.16, -0.07, (-100, -38), "tip"),
        ("Secondary", 7, (0.55, 1.0), 0.17, 0.0, (-98, -42), WHITE),
        ("Covert", 6, (0.36, 0.55), 0.18, 0.07, (-95, -50), WHITE),
    ]
    for name, count, (short, long), width, lift, (first, last), colour in rows:
        for index in range(count):
            t = 0.04 + 0.92 * index / (count - 1)
            tint = colour
            if colour == "tip":
                tint = FEATHER_TIP
                if VARIANT == "rainbow":
                    import colorsys
                    tint = tuple(round(c * 255) for c in colorsys.hsv_to_rgb(0.95 - 0.8 * t, 0.42, 1.0))
            angle = math.radians(first + (last - first) * t)
            feather(f"{name}{sign}{index}", t, short + (long - short) * t, width, lift - 0.004 * index, angle, tint)
    return placed


def main():
    data = r.config.load()
    import build_fluffy as fluffy
    sheep.reset_scene()
    built = fluffy.build()
    sources = {obj.name: obj for obj in built["Base"] + built["Addons"]}
    for name in (fluffy.BASE_COLLECTION, fluffy.ADDON_COLLECTION):
        bpy.data.collections[name].hide_render = True
    r.stage()
    collection = bpy.data.collections.new("Icon")
    bpy.context.scene.collection.children.link(collection)
    breed = dict(data["Breeds"]["Merino"])
    breed.update(WoolColor=WHITE, FaceColor=(250, 236, 214), LegColor=(250, 236, 214), WoolSize=1.08)
    # Warm-up: the first shader compile can miss the face picture.
    r.dress(built, sources, breed, data, collection)
    bpy.context.scene.render.filepath = str(OUT.with_name("_warmup.png"))
    bpy.ops.render.render(write_still=True)
    OUT.with_name("_warmup.png").unlink(missing_ok=True)
    for obj in list(collection.objects):
        bpy.data.objects.remove(obj)
    r.reset_camera()
    r.dress(built, sources, breed, data, collection)
    placed = list(collection.objects)
    # Wings from the top of the back (rig Back (0, 2.08, 0.3) is Blender (0, 0.3, 2.08)).
    for sign in (1, -1):
        placed += wing(sign, (sign * 0.3, 0.35, 2.0), collection)
    # Gold hooves: a band round the foot of each leg.
    for obj in list(collection.objects):
        if obj.name.startswith("Leg"):
            bpy.context.view_layer.update()
            low, high = r.world_bounds(obj)
            centre = ((low.x + high.x) / 2, (low.y + high.y) / 2, low.z + 0.13)
            radius = (high.x - low.x) / 2 * 1.08
            ellipsoid(f"Hoof{obj.name}", centre, ((1, 0, 0), (0, 1, 0), (0, 0, 1)), (radius, radius, 0.15), GOLD,
                      collection, "Metal")
    if HALO:
        # A gold ring floating over the head (rig HornTop (0, 2.26, -1.2) is Blender (0, -1.2, 2.26)).
        bpy.ops.mesh.primitive_torus_add(major_radius=0.42, minor_radius=0.075, location=(0, -1.12, 2.78),
                                         rotation=(math.radians(-14), 0, 0), major_segments=48, minor_segments=16)
        ring = bpy.context.active_object
        for collection_ in ring.users_collection:
            collection_.objects.unlink(ring)
        collection.objects.link(ring)
        for polygon in ring.data.polygons:
            polygon.use_smooth = True
        r.paint(ring, GOLD, "Metal")
    r.frame_all(list(collection.objects))
    bpy.context.scene.render.filepath = str(OUT)
    bpy.ops.render.render(write_still=True)
    print(f"Rendered {OUT}")


main()
