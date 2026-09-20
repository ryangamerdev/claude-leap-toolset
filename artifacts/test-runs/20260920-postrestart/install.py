from pathlib import Path
import datetime, hashlib, json, os, subprocess
root = Path('/Users/ryan/src/claude-leap')
source = root / 'dist/claude-leap.app'
target = Path('/Users/ryan/Applications/claude-leap.app')
stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
backup = root / 'artifacts/backups' / ('leap-recording-' + stamp)
backup.mkdir(parents=True)
stage = target.parent / ('claude-leap-stage-' + stamp + '.app')
subprocess.run(['/usr/bin/ditto', str(source), str(stage)], check=True)
subprocess.run(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(stage)], check=True)
if target.exists(): os.rename(target, backup / 'claude-leap.app')
try:
    os.rename(stage, target)
except Exception:
    if (backup / 'claude-leap.app').exists(): os.rename(backup / 'claude-leap.app', target)
    raise
binary = target / 'Contents/MacOS/claude-leap'
sha = hashlib.sha256(binary.read_bytes()).hexdigest()
assert sha == hashlib.sha256((source / 'Contents/MacOS/claude-leap').read_bytes()).hexdigest()
metadata = dict(installed=str(target), backup=str(backup / 'claude-leap.app'), sha256=sha, verification='build and signature passed; native MCP verification pending restart', installedAt=datetime.datetime.now().astimezone().isoformat())
(root / 'artifacts/test-runs/20260920-postrestart/install.json').write_text(json.dumps(metadata, indent=2) + '\n')
print(json.dumps(metadata, indent=2))
