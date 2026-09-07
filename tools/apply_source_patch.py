"""Apply the reviewed, SHA-256-guarded source repair exactly once."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'tools/repair_manifest.json').read_text())
for name, spec in manifest.items():
    path = root / name
    text = path.read_text(encoding='utf-8')
    digest = lambda value: hashlib.sha256(value.encode('utf-8')).hexdigest()
    if digest(text) == spec['result_sha256']:
        continue
    if digest(text) != spec['base_sha256']:
        raise SystemExit(f'Source changed unexpectedly: {name}')
    for start, end, replacement in sorted(spec['edits'], reverse=True):
        text = text[:start] + replacement + text[end:]
    if digest(text) != spec['result_sha256']:
        raise SystemExit(f'Patch verification failed: {name}')
    path.write_text(text, encoding='utf-8')
    print(f'Repaired {name}')
