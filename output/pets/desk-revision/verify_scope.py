from pathlib import Path
import hashlib
import json
import zipfile

run = Path(__file__).resolve().parent/'DarkShrill'
changed, unchanged = [], []
with zipfile.ZipFile(run/'previous-frames.zip') as archive:
    for name in archive.namelist():
        if not name.endswith('.png'):
            continue
        state = Path(name).parts[1]
        same = hashlib.sha256(archive.read(name)).digest() == hashlib.sha256((run/name).read_bytes()).digest()
        if state in ['running', 'review']:
            assert not same, name
            changed.append(name)
        else:
            assert same, name
            unchanged.append(name)
assert len(changed) == 32 and len(unchanged) == 112
report = {'ok': True, 'changed_states': ['running', 'review'], 'changed_frames': len(changed), 'unchanged_frames': len(unchanged)}
(run/'qa'/'scope-verification.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report))
