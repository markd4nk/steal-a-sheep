# God models (Blender)

Each god is a Python file of shapes (`zeus.py`): ellipsoids, tapered capsules, boxes and rings, each with a colour
and the bone it moves with. `build.py` turns them into a game mesh in Blender 5.2 (numpy only, no add-ons):

1. `build.hi(god)`: the shapes merged into one closed surface (a signed-distance field meshed with surface nets),
   coloured per vertex. About 160k quads at `h=0.03`; only for looking at and for the next steps.
2. `build.low(god, 6000)`: decimated to 6,000 triangles (the face, beard and fists keep more: `detail()` in the
   god's file), the dense mesh's normals copied on so it shades smoothly, unwrapped.
3. `build.paint(god)`: the one 1024 texture, painted straight from the shapes: every texel's point is pulled onto the
   true surface and takes the colour of the shape forming it there, so colour edges are exact; soft occlusion
   darkens creases. About 90 s.
4. `build.rig(god)`: a Root bone on the ground, then the god's `BONES` (R15-style names). Weights come from the
   shapes too: a vertex follows the shape it's on, blended with neighbouring shapes' bones at joints; `reweight()`
   in the god's file overrides (Zeus's skirt hangs from the hips and follows each thigh towards the hem).

`gait.py` holds the walk and run as functions of the cycle's phase, with rotations in the rig's axes, so the same
numbers can drive Roblox `Bone.Transform`. Poses are grounded (the body drops until the lowest sole is on the
floor) and the bolt hand turns so the bolt points up. `render.py` makes the mock-ups: the neon bolt as the game's
blocks, a floor, stills and a walk-then-run clip (`demo`, `encode`; needs ffmpeg).

Run inside Blender (the Blender MCP's `execute_blender_code`):

```python
import sys; sys.path.insert(0, r"<repo>\art\gods")
import build, gait, render
build.hi("zeus", h=0.03); build.low("zeus", 6000); build.paint("zeus"); rig = build.rig("zeus")
```

Exported for Roblox as FBX (rest pose, mesh and armature, texture embedded, forward -Z, up Y) to `out/`, which git
ignores until a look is approved.
