from pathlib import Path
import sqlite3,json
p=Path(__file__).parent
c=sqlite3.connect('file:/Users/ryan/src/claude-leap/.leap/leap.db?mode=ro',uri=True)
with sqlite3.connect(p/'native-evidence.db') as target:c.backup(target)
high=c.execute('select max(seq) from records').fetchone()[0]
scope="seq<=? AND session=?"
args=[str(high),'A16C3242-997E-4E00-946D-F07E234DF73F']
q="SELECT MIN(seq),COUNT(*) FROM records WHERE "+scope+" AND kind='ax_notification' GROUP BY session,json_extract(payload,'$.notification'),json_extract(payload,'$.elementHash') HAVING MIN(seq)>CAST(? AS INTEGER) ORDER BY MIN(seq) LIMIT ?"
allrows=c.execute(q,args+['0','1000']).fetchall()
pages=[];cursor=0
while True:
 rows=c.execute(q,args+[str(cursor),'1']).fetchall()
 if not rows:break
 pages+=rows;cursor=rows[-1][0]
assert pages==allrows
verdicts=c.execute("SELECT json_extract(payload,'$.phase'),json_extract(payload,'$.outcome'),COUNT(*) FROM records WHERE "+scope+" AND kind='expectation_result' GROUP BY 1,2",args).fetchall()
assert ('after','met',2) in verdicts
(p/'query-check.json').write_text(json.dumps({'through':high,'eventGroups':len(allrows),'events':sum(r[1] for r in allrows),'paginationMatches':True,'nativeVerdicts':verdicts,'scope':'SQL support check; new tool native validation pending'},indent=2)+'\n')
print((p/'query-check.json').read_text())
