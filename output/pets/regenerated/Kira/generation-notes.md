# Kira regenerated animation sources

Generated with built-in ImageGen, grounded in `assets/kira/frames/idle/00.png`.
Gray/white plush 3D Siberian Husky; anatomical right eye brown and left eye blue (viewer left/right when frontal). Sixteen independently drawn chronological poses per state in 4x4 source grids.

- idle: breathing, tail movement and a progressively closing/reopening blink. Transparent-source red/yellow matte fragments removed by bundled chroma cleanup.
- running-right: two articulated canine gallop cycles, brown profile eye, flat magenta source.
- running-left: independently generated gallop with blue profile eye; never mirrored.
- waving: same viewer-left attached forepaw lifts, extends, bends and lowers; viewer-right forepaw stays planted. Replaces rejected alternating-paw revision.
- jumping: one stand/crouch/takeoff/apex/descent/landing/settle sequence. Replaces four-hop revision. Whole-row relative grid height preserved by extraction adapter.
- failed: ears droop, head bows and eyes close, then recovery.
- waiting: expectant head tilt, perked ears and raised gaze.
- running: seated focused thought, narrowing eyes and small head turn/nod; no foot-running.
- review: downward inspection scan and attached forepaw checking movement, then approving recovery.

Every source explicitly requested complete separated puppy silhouettes, constant scale, fixed camera, no text, marks, effects, scene, floor or shadows. Sources besides idle use flat magenta #FF00FF; exact transparency is produced by the bundled extraction pipeline.

`process.py` adapts the bundled connected-component extractor, frame inspector and atlas compositor to CodexMeter's sixteen-frame extension. No pose synthesis, duplication, blending, optical interpolation or procedural animation. Actual final all-state inspector returned `ok: true`, no errors or warnings. Final despill and motion preview acceptance belong to the parent workflow; no Pets upload or record mutation was performed.
