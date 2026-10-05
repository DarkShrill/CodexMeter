"""Final deterministic cleanup of the CodexMeter 16-frame extension."""
import argparse
import json
from pathlib import Path
import runpy
import subprocess
import sys
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('name', choices=['Kira', 'DarkShrill'])
args = parser.parse_args()
run = Path(__file__).resolve().parent/args.name
scripts = Path('C:/Users/e.papa/.codex/plugins/cache/openai-curated-remote/work-pets/0.1.6/skills/create-pet/scripts')
adapter = runpy.run_path(str(run/'process.py'), run_name='pet_adapter')
adapter['atlas']()
atlas = run/'final'/'codexmeter-atlas.png'
clean = run/'final'/'codexmeter-atlas-clean.png'
result = subprocess.run([sys.executable, str(scripts/'despill_chroma_edges.py'), str(atlas), '--output', str(clean), '--chroma-key', '#FF00FF', '--json-out', str(run/'qa'/'chroma-despill.json')], capture_output=True, text=True)
if result.returncode:
    raise RuntimeError(result.stdout+result.stderr)
image = Image.open(clean).convert('RGBA')
assert image.size == (3072, 1872)
for row, state in enumerate(adapter['STATES']):
    for column in range(16):
        image.crop((column*192, row*208, (column+1)*192, (row+1)*208)).save(run/'frames'/state/f'{column:02}.png')
adapter['review'](adapter['STATES'], [])
report = json.loads((run/'qa'/'frame-review.json').read_text())
assert report['ok'], report.get('errors')
print(f'{args.name}: one final despill pass and bundled inspection passed.')
