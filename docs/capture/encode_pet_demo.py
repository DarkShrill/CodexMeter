"""Encode production QML captures into a compact, looping README GIF."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
paths = sorted((ROOT / "build/docs-capture/pet-frames").glob("frame-*.png"))
SCENE_COUNT = 10
FRAME_COUNT = SCENE_COUNT * 32
if len(paths) != FRAME_COUNT:
    raise SystemExit(f"Expected {FRAME_COUNT} frames, got {len(paths)}")
frames = [Image.open(path).convert("RGB") for path in paths]
# One shared palette prevents background/text colors flickering between frames.
samples = Image.new("RGB", (960, 600 * SCENE_COUNT * 2))
for i, frame_index in enumerate(range(0, FRAME_COUNT, 16)):
    samples.paste(frames[frame_index], (0, i * 600))
palette = samples.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
encoded = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
target = ROOT / "docs/images/pet-in-action.gif"
encoded[0].save(target, save_all=True, append_images=encoded[1:], duration=80,
                loop=0, optimize=True, disposal=1)
# Keep a static QA sheet beside build outputs for checking all contexts at once.
sheet = Image.new("RGB", (960, 300 * ((SCENE_COUNT + 1) // 2)), "#122237")
for scene in range(SCENE_COUNT):
    sheet.paste(frames[scene * 32 + 12].resize((480, 300)),
                ((scene % 2) * 480, (scene // 2) * 300))
sheet.save(ROOT / "build/docs-capture/pet-contact-sheet.png")
with Image.open(target) as gif:
    duration = sum(gif.seek(i) or gif.info.get("duration", 0) for i in range(gif.n_frames))
    assert gif.size == (960, 600) and gif.info.get("loop") == 0
    assert duration == FRAME_COUNT * 80, duration
    print(f"{target}: {gif.n_frames} frames, {duration / 1000:.2f}s, {target.stat().st_size / 1024:.0f} KiB")
