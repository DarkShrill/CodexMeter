"""Clean only the two newly generated desk animation rows."""
from pathlib import Path
import json
import runpy
import subprocess
import sys
from PIL import Image

run = Path(__file__).resolve().parent/'DarkShrill'
states = ['running', 'review']
raw = Image.new('RGBA', (3072, 416))
for row, state in enumerate(states):
    for col in range(16):
        raw.alpha_composite(Image.open(run/'frames'/state/f'{col:02}.png').convert('RGBA'), (col*192, row*208))
raw_path = run/'final'/'desk-rows-raw.png'
clean_path = run/'final'/'desk-rows-clean.png'
raw.save(raw_path)
script = 'C:/Users/e.papa/.codex/plugins/cache/openai-curated-remote/work-pets/0.1.6/skills/create-pet/scripts/despill_chroma_edges.py'
result = subprocess.run([sys.executable, script, str(raw_path), '--output', str(clean_path), '--chroma-key', '#FF00FF', '--json-out', str(run/'qa'/'chroma-despill.json')], capture_output=True, text=True)
if result.returncode:
    raise RuntimeError(result.stdout+result.stderr)
clean = Image.open(clean_path).convert('RGBA')
for row, state in enumerate(states):
    for col in range(16):
        clean.crop((col*192, row*208, (col+1)*192, (row+1)*208)).save(run/'frames'/state/f'{col:02}.png')
adapter = runpy.run_path(str(run/'process.py'), run_name='pet_adapter')
adapter['review'](adapter['STATES'], [])
adapter['atlas']()
assert json.loads((run/'qa'/'frame-review.json').read_text())['ok']
print('Two new desk rows cleaned and all nine rows inspected.')
