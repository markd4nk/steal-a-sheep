"""The store's two Robux sheep for their product icons (make_product_icons.py): Shear a Sheep's fluffy sheep, built and
dressed by its own art/icons/render_sheep_icons.py with the camera and lights of its store icons, in this game's looks
(GameConfig's GoldenFleece and Kronos; Kronos is Shear a Sheep's Time Sheep in the same colours). Like
DESIGN/ui/art/pegasus.py it only reads that checkout (SHEAR_ART), which needs its face pictures in
art/sheep/renders/fluffy/faces. The game's studs on the wool aren't drawn.

    blender -b --factory-startup -P art/store/render_robux_sheep.py -- [<out folder>]

Writes <out folder>/GoldenFleece.png and Kronos.png (1024 px, transparent), by default art/store/sheep/ (gitignored).
"""

import os
import pathlib
import sys

ROOT = pathlib.Path(os.environ.get("SHEAR_ART", r"C:\Users\markf\breed_render"))
sys.path.insert(0, str(ROOT / "art" / "icons"))
sys.path.insert(0, str(ROOT / "art" / "sheep"))
sys.dont_write_bytecode = True

import bpy  # noqa: E402

import build_sheep as sheep  # noqa: E402
import render_sheep_icons as r  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = pathlib.Path(args[0]) if args else HERE / "sheep"

# GameConfig's looks, each on the Shear a Sheep breed it was taken from (a build's Id must stay that breed's).
LOOKS = {
    "GoldenFleece": ("Merino", dict(Id="GoldenFleece", WoolColor=(255, 196, 64), WoolSize=1, FaceColor=(246, 226, 206),
                                    LegColor=(246, 226, 206), HornStyle="BigCurl", HornColor=(240, 228, 198),
                                    Face="Happy", SpecialFX=None)),
    "Kronos": ("TimeSheep", dict(WoolColor=(246, 232, 196), WoolSpotColor=(236, 214, 166), FaceColor=(250, 240, 220),
                                 LegColor=(150, 112, 70))),
}


def main():
    data = r.config.load()
    breeds = {}
    for name, (base, look) in LOOKS.items():
        breed = dict(data["Breeds"][base])
        breed.update(look)
        breeds[name] = breed
    import build_fluffy as fluffy
    import mock_wave1 as w

    sheep.reset_scene()
    # A build's mock-ups read the first kit's layout, made first, as render_sheep_icons.main does.
    w.DATA = r.config.load()
    w.BUILT = sheep.build()
    for name in (sheep.BASE_COLLECTION, sheep.ADDON_COLLECTION):
        bpy.data.collections[name].hide_render = True
    built = fluffy.build()
    sources = {obj.name: obj for obj in built["Base"] + built["Addons"]}
    for name in (fluffy.BASE_COLLECTION, fluffy.ADDON_COLLECTION):
        bpy.data.collections[name].hide_render = True
    r.stage()
    OUT.mkdir(parents=True, exist_ok=True)
    collection = bpy.data.collections.new("Icon")
    bpy.context.scene.collection.children.link(collection)
    # A throwaway render first: the first shader compile can miss the face picture.
    r.dress(built, sources, breeds["GoldenFleece"], data, collection)
    bpy.context.scene.render.filepath = str(OUT / "_warmup.png")
    bpy.ops.render.render(write_still=True)
    (OUT / "_warmup.png").unlink(missing_ok=True)
    for name, breed in breeds.items():
        for obj in list(collection.objects):
            bpy.data.objects.remove(obj)
        r.reset_camera()
        r.dress(built, sources, breed, data, collection)
        bpy.context.scene.render.filepath = str(OUT / f"{name}.png")
        bpy.ops.render.render(write_still=True)
        print(f"Rendered {name}")


main()
