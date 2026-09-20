from pathlib import Path
import shutil, subprocess, hashlib, json
from datetime import datetime, timezone
root=Path(__file__).resolve().parents[3]
backup=root/'artifacts/backups/20260920-keyboard-target'
backup.mkdir(parents=True,exist_ok=True)
staged=backup/'staged.app'; previous=backup/'previous.app'
installed=Path.home()/'Applications/claude-leap.app'
if staged.exists() or previous.exists(): raise SystemExit('Existing rollback/stage: inspect before rerunning')
shutil.copytree(root/'dist/claude-leap.app',staged,symlinks=True)
subprocess.run(['codesign','--verify','--deep','--strict',str(staged)],check=True)
installed.rename(previous)
try: staged.rename(installed)
except Exception:
    previous.rename(installed)
    raise
subprocess.run(['python3','scripts/install.py','--skills-only'],cwd=root,check=True)
for host in ['.claude','.codex']:
    subprocess.run(['diff','-rq',str(root/'skills/claude-leap'),str(Path.home()/host/'skills/claude-leap')],check=True)
record=dict(installed_at=datetime.now(timezone.utc).isoformat(),sha256=hashlib.sha256((installed/'Contents/MacOS/claude-leap').read_bytes()).hexdigest(),rollback=str(previous),rollback_local_only=True,skills_synced=True,native_acceptance='pending restart',registration='leap unchanged',build='passed',focused_tests='9 passed',scope='process-directed app keyboard in foreground/background; insights off')
(root/'artifacts/test-runs/20260920-keyboard-target/install.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps(record,indent=2))
