from pathlib import Path
import hashlib
import json
import zipfile
import argparse
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
STATES = ['idle', 'running-right', 'running-left', 'waving', 'jumping', 'failed', 'waiting', 'running', 'review']
TIMES = {'idle': [160]+[100]*14+[300], 'running-right': [100]+[65]*14+[140], 'running-left': [100]+[65]*14+[140], 'waving': [130]+[80]*14+[300], 'jumping': [140]+[80]*14+[260], 'failed': [140]+[90]*14+[300], 'waiting': [160]+[90]*14+[260], 'running': [150]+[80]*14+[220], 'review': [160]+[85]*14+[260]}

parser = argparse.ArgumentParser()
parser.add_argument('--regenerated', action='store_true')
parser.add_argument('--pet', choices=['Kira', 'DarkShrill'])
parser.add_argument('--frames-root', type=Path)
args = parser.parse_args()
for name in ([args.pet] if args.pet else ['Kira', 'DarkShrill']):
    source = args.frames_root or ((OUT/'regenerated'/name/'frames') if args.regenerated else (ROOT/'assets'/name.lower()/'frames'))
    dest = OUT/name
    dest.mkdir(parents=True, exist_ok=True)
    contact = Image.new('RGB', (192*16, 232*9), '#f5f6f8')
    preview, durations, rows = [], [], []
    for row, state in enumerate(STATES):
        paths = sorted((source/state).glob('*.png'))
        assert [p.name for p in paths] == [f'{i:02}.png' for i in range(16)], (name, state)
        hashes = set()
        state_preview = []
        for col, path in enumerate(paths):
            frame = Image.open(path).convert('RGBA')
            assert frame.size == (192, 208), path
            assert frame.getbbox() is not None, path
            assert frame.getchannel('A').getextrema() == (0, 255), path
            hashes.add(hashlib.sha256(frame.tobytes()).hexdigest())
            canvas = Image.new('RGB', (192, 232), '#f5f6f8')
            canvas.paste(frame, (0, 24), frame)
            ImageDraw.Draw(canvas).text((5, 5), f'{state} {col+1}/16', fill='#141923')
            contact.paste(canvas, (col*192, row*232))
            preview.append(canvas)
            state_preview.append(canvas)
        minimum_unique = 15 if args.regenerated else 4
        assert len(hashes) >= minimum_unique, (name, state, 'insufficient distinct generated frames')
        state_dir = dest/'states'
        state_dir.mkdir(exist_ok=True)
        state_preview[0].save(state_dir/f'{state}.gif', save_all=True, append_images=state_preview[1:], duration=TIMES[state], loop=0, disposal=2, optimize=False)
        durations.extend(TIMES[state])
        rows.append({'state': state, 'frames': [f'frames/{state}/{p.name}' for p in paths], 'unique_frames': len(hashes), 'durations': TIMES[state]})
    contact.save(dest/'contact-sheet.png')
    preview[0].save(dest/'all-states.gif', save_all=True, append_images=preview[1:], duration=durations, loop=0, disposal=2, optimize=False)
    transition = preview[:16]+preview[64:80]+preview[:16]
    transition[0].save(dest/'idle-jump-idle.gif', save_all=True, append_images=transition[1:], duration=TIMES['idle']+TIMES['jumping']+TIMES['idle'], loop=0, disposal=2, optimize=False)
    manifest = {'schema': 'codexmeter-16-pose-extension', 'name': name, 'cell_size': [192, 208], 'rows': rows}
    (dest/'validation.json').write_text(json.dumps({'ok': True, 'states': 9, 'frames': 144, 'regenerated': args.regenerated, 'unique_frames_by_state': {r['state']: r['unique_frames'] for r in rows}, 'checks': ['exact frame names', '192x208', 'nonempty', 'transparent background', f'at least {minimum_unique} distinct images per state'], 'motion_semantics': 'Requires separate visual review; pixel uniqueness alone does not prove articulated motion.'}, indent=2))
    with zipfile.ZipFile(dest/'frames.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for state in STATES:
            for path in sorted((source/state).glob('*.png')):
                archive.write(path, f'frames/{state}/{path.name}')
        archive.writestr('frames/frames-manifest.json', json.dumps(manifest, indent=2))
    print(f'{name}: 144 frames verified; {dest / "frames.zip"}')
