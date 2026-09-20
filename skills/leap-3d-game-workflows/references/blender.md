# Blender: script construction, Leap inspection

## Prepare an editable scene

Identify Blender's installed version and the target `.blend`. Use that version's Python API documentation or local introspection before relying on version-sensitive operators, material inputs, or render settings. Entry points include Blender's embedded Python and its command-line script execution; a headless process operates on a file, not on unsaved edits in the open UI.

Choose one authoritative working copy. Save UI work before a headless job reads it, and avoid letting the headless process overwrite a file the editor will later save from stale memory. Prefer a new output file for an initial generated asset and open that result through Leap.

Use `bpy.data` and explicit object references where possible. Operators often depend on active object, selection, mode, and editor context: establish those deliberately when an operator is needed. Name task-owned objects and collections so a rerun replaces or updates only its own work. Retain generation scripts with the project.

## Build, inspect, refine

- Block out silhouette and proportions before detail. Use appropriate primitives, curves, meshes, symmetry, and modifiers. Inspect front, side, and three-quarter views; a single camera can conceal shape errors.
- Refine junctions, silhouette, face, hands, and deformation-critical areas. Smooth shading or subdivision does not repair poor topology. For static stylized work, separate parts can be acceptable; animation requires testing how they meet and bend.
- Add materials, UVs/textures when needed, lighting, and a camera. Render a modest preview first. Inspect actual pixels for intersections, normals, clipping, material mistakes, and unintended highlights; use scene data for counts, bounds, references, and numeric transforms.
- For rigging, define the necessary bones/controls and weights, then test extreme and ordinary poses. Look for collapsing joints, detached parts, and unwanted influence. Add facial controls or animation only when the requested use requires them.
- For animation, inspect several timeline positions and actual playback/rendered motion. A correct rest pose does not prove usable deformation or timing.

Use Leap's AX tree for Outliner, properties, menus, and dialogs where accessible. Treat the 3D viewport, sculpting, node canvas, UV editor, and timeline as visual surfaces when AX is incomplete. Observe the region before shortcuts or gestures; recover from an accidental mode change before continuing. Use selection labels and structured scene inspection to distinguish look-alike objects.

## Example: Mickey Mouse character

This example demonstrates the workflow, not a required subject for other requests. Match the user's chosen depiction and intended use; do not silently replace it with a generic mouse.

For a stylized static Mickey, begin with the head and round ears, torso, muzzle/face, arms, legs, gloves, shorts/buttons, shoes, and tail. Establish the recognizable silhouette and proportions before small detail. Build in a dedicated collection with named parts and materials. Do not mistake a pile of intersecting spheres for a finished character simply because the major colors are present.

Render front, profile, and three-quarter views. Refine the facial shape, ear placement across angles, glove fingers, shoe shape, clothing transitions, and limb connections. If the request is animation-ready, additionally create deformation-appropriate topology, rig and weights, and test smiling/posing/walking as applicable. If it is a statue or render, do not add unnecessary game/rig requirements.

## Save and handoff

Save the `.blend`, scripts, and required textures. Pack assets or preserve a documented relative layout so another machine can reopen the project. Reopen and verify materials and object hierarchy, then render the saved scene. If exporting for a game, check scale, axes, transforms, normals, materials, skeleton, and animation in the destination engine; validate the imported artifact rather than the source alone.

For render completion, inspect process exit/logs and the produced image/frame sequence. For long UI jobs use observable progress/completion and a bounded timeout. Report partial render ranges or missing dependencies explicitly.

Reference: [Blender Python API](https://docs.blender.org/api/current/). Select the documentation matching the installed release.
