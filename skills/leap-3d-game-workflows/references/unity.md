# Unity: project code, editor verification, play-testing

## Work in the actual project

Identify the Unity version from the project, render pipeline, installed packages, target platform, input setup, existing scenes, and user changes. Work within those conventions. Do not upgrade Unity, replace the render pipeline, or migrate input systems just to fit a generic recipe.

Use C# for gameplay and editor automation. Follow the project's assembly layout and keep editor-only code out of runtime assemblies. Prefer Unity's asset/scene APIs for creating prefabs, materials, scenes, and serialized relationships. Preserve asset identities and `.meta` files; avoid hand-editing serialized scene references when editor APIs can do it reliably.

Do not open another writable editor process against an already-open project. Coordinate script execution, imports, and file ownership with the active editor. If command-line processing is useful, use a separate task-owned copy or close/save the editor when the task permits it.

## Implement a playable slice

Implement the smallest loop that demonstrates the requested game: player input, a goal, feedback, and restart/failure behavior as applicable. Use temporary shapes/assets when they help test mechanics early, then replace them with the requested art. Avoid spending the whole task polishing a scene that has no working gameplay.

After writing scripts or importing assets, wait for compilation/import to finish. Inspect Console/logs and resolve relevant errors before claiming the scene is ready. Scene creation or successful compilation does not prove input, collisions, state transitions, or game feel.

Use Leap to inspect Hierarchy, Inspector, Scene/Game views, Console, and dialogs. Verify active scene, selected object, and focused panel before shortcuts. Identify inaccessible custom canvases through screenshots and supported gestures. Confirm an action's effect before issuing another context-dependent command.

## Play-test through Leap

Enter Play mode and verify that it actually started. Focus the Game view without confusing it with the Scene view. Exercise the requested controls, movement, camera, collisions, interactions, UI, win/fail/restart states, and any animation transitions. Capture visual evidence and inspect errors during and after play.

Continuous movement and simultaneous controls may require held keys, explicit key release, held mouse buttons, or timed input. Verify that Leap exposes the needed primitives. Repeated `press_key` calls are not equivalent to a held key. If only a scripted test can currently exercise a mechanic, use it where useful but report that direct Leap play-testing remains unverified. Relative/captured mouse-look is a distinct capability from an absolute canvas drag.

Exit Play mode and verify cleanup. Do not assume edits made during Play mode persist into the saved scene. Save required scene/prefab changes outside play, then reopen/re-enter to verify persistence and restart behavior.

## Blender asset integration and delivery

For an imported character, verify scale/orientation, mesh/materials, rig mapping, animation clips, root motion where applicable, colliders, and representative lighting. Inspect deformation in motion in the actual scene. Fix source/export/import settings deliberately rather than compensating with unexplained transforms throughout the hierarchy.

Run the project's relevant tests and make a playable build when requested. Launch that build and verify startup and the core loop; editor Play mode alone does not prove the build works. Document tested platform and remaining device-specific controls.

Deliver the project changes, startup scene/instructions, necessary source assets, and a short preview. Link any requested build. Preserve existing user work and identify limitations such as untested gamepad controls or unavailable continuous-input tools.

Reference: [Unity documentation](https://docs.unity.com/). Use the project-matching editor/API version.
