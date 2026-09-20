import sqlite3,json
from pathlib import Path
root=Path('/Users/ryan/src/claude-leap')
out=root/'artifacts/test-runs/20260920-recording-query-fix'
c=sqlite3.connect(f'file:{root}/.leap/leap.db?mode=ro',uri=True)
with sqlite3.connect(out/'native-evidence.db') as dest: c.backup(dest)
base="SELECT CAST(j.key AS INTEGER)+1 FROM records r,json_each(r.payload,'$.nodes') j WHERE r.seq=? AND CAST(j.key AS INTEGER)+1>{cursor} AND instr(lower(j.value),lower(?))>0 ORDER BY CAST(j.key AS INTEGER) LIMIT ?"
args=['9','0','Coaching notes','3']
old=c.execute(base.format(cursor='?'),args).fetchall()
fixed=c.execute(base.format(cursor='CAST(? AS INTEGER)'),args).fetchall()
assert old==[] and fixed==[(79,),(80,)],(old,fixed)
assert c.execute(base.format(cursor='CAST(? AS INTEGER)'),['9','79','Coaching notes','3']).fetchall()==[(80,)]
result={'old':old,'fixed':fixed,'exclusiveCursorPassed':True,'evidence':'SQL regression only; native rebuilt MCP verification pending'}
(out/'query-regression.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
