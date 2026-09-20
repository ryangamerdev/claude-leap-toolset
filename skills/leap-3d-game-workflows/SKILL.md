---
name: leap-3d-game-workflows
description: Build and refine Blender models and Unity games using scripting for construction and Leap for editor interaction, visual inspection, and play-testing. Use for 3D assets, characters, scenes, rigs, animation, or Unity gameplay work; not for image-only generation or unrelated native-app automation.
---

# Blender and Unity with Leap

Produce editable assets and working projects, using Leap as the native UI interface. Combine direct scripting with visual feedback: constructing an object or compiling code is only an intermediate result. Inspect what the user will actually see and use.

This is the intended workflow assuming the necessary Leap capabilities are available. Discover the installed tool schemas at execution time. Missing capabilities are gaps to report or implement within the user's authorized scope, not permission to invent tool calls or claim unobserved success. In the Leap repository, track those gaps in [FEATURES.md](../../docs/FEATURES.md), especially the ART rows; the checklist is not required when this skill is installed elsewhere.

## Select the route

- For Blender modeling, materials, rigging, animation, and rendering, read [Blender workflow](references/blender.md).
- For Unity gameplay, scene assembly, asset import, editor tooling, and play-testing, read [Unity workflow](references/unity.md).
- For a Blender asset going into Unity, use both in that order and verify the imported asset in Unity. Do not assume an export proves compatibility.

Establish the requested deliverable and existing project first. A recognizable static character, a polished render, and a game-ready animated character require different work. Use the user's chosen character and style; ask only when a missing decision materially changes the result. Do not expand a simple modeling request into a rig, game, or publishing task.

## Shared execution loop

1. Inspect the workspace, installed app version, existing project conventions, and user's current work before editing. Choose a task-owned collection, asset folder, or scene; save a recoverable checkpoint before changing existing content.
2. Prefer Blender Python or Unity C#/editor APIs for precise, repeatable construction. Use a direct application bridge if one is actually available; otherwise use the app's supported script or command-line entry points. Leap remains the UI inspection and interaction layer. Do not make UI clicking the only construction mechanism unless the user requests a UI-only trial.
3. Read `get_app_state` for the target app/window. Use current labels or element indices for accessible controls. For custom viewports, get a fresh screenshot and derive coordinates in its reported scale. Capture after orbiting, panning, switching editors, or changing selection when those changes determine the next action.
4. Act through Leap, then inspect the returned state. Use screenshots or renders to verify geometry, lighting, deformation, animation, and gameplay that AX cannot express. Combine AX, structured application data, and visuals rather than trusting any one source for every question.
5. Adjust the smallest useful part, repeat, and save. Keep scripts rerunnable by updating explicitly owned objects/assets rather than accumulating duplicates or clearing the user's scene.
6. Reopen the saved artifact or scene and verify required behavior survives. Deliver project/source paths, a representative preview, checks performed, and specific unfinished work.

## Interaction invariants

Use the [base Leap skill](../claude-leap/SKILL.md) for targeting, state, and error semantics. Native pointer gestures should keep the same window-targeted delivery whether the app is foreground or background. `foreground:true` requests activation; announce it. Keyboard fallback has separate focus behavior. Preserve the user's actual cursor and current work, and verify coexistence rather than assuming it.

Blender and Unity route many shortcuts according to the focused editor or viewport. Confirm the active region, selection, mode, and keyboard focus before an operation. App-level focus alone is insufficient. Prefer explicit data/API operations when region context is ambiguous.

Inspect the schema before requesting middle/right-button dragging, hover, held keys, key-up, or timed button sequences. These are workflow requirements, not necessarily existing Leap parameters. If an operation has no supported UI primitive, use an equivalent supported application command/API and verify the result. Record that as a UI capability gap rather than declaring UI parity.

After a failed or ambiguous action, observe once before retrying. Do not blindly repeat extrude, duplicate, save/import, or text submission. After an action succeeds but the observation fails, re-observe without replaying the action. For asynchronous compile/import/render work, use bounded waits on meaningful UI state, logs, or output artifacts; a settled tree does not establish job completion.

## Leap comparison campaign storage

When working on the claude-leap comparison campaign, keep scripts and tests in the repository’s `scripts/` and `tests/`, reports in `docs/research/`, and raw logs/previews/project artifacts under `artifacts/`. Keep the paired Mickey baseline and `.blend` files in `artifacts/blender/mickey-head/`. Do not use external scratch folders for evidence. For unrelated user projects, follow that project’s requested output location.

## Completion standard

Check the requested result, not a preset aesthetic or arbitrary polygon count. A static model needs convincing shape/materials and a valid saved file; a game asset also needs appropriate topology, transforms, export/import, and any requested rig/animation; a game needs runnable mechanics and direct play-testing. A good-looking screenshot cannot substitute for editable geometry or working gameplay.

Use the tools needed for the real deliverable. Separately record Leap-only trials when assessing UI parity. A script-based workaround can complete the user's asset but does not certify a missing Leap input feature. This skill itself makes no Blender or Unity certification claim.
