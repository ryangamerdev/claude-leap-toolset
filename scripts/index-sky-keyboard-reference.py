#!/usr/bin/env python3
"""Index the supplied full reference manifest; prints pointers, never sends UI input."""
from pathlib import Path
import csv, json
root=Path('/Users/ryan/src/sky/native/ghidra/decompiled/all')
rows=list(csv.DictReader((root/'manifest.tsv').open(),delimiter='\t'))
names=(root/'names-demangled.txt').read_text().splitlines()
assert len(rows)==len(names), 'Reference manifest/name alignment changed'
terms=['performKeyboardAction','targetForKeyboardEvent','outOfProcessTarget','SyntheticAppFocusEnforcer','SynthesizedEvent.type(', 'SynthesizedEvent.send(', 'prepareToInteract','ProcessType.containingElement','VirtualCursor']
selected=[dict(address=r['addr'],shard=r['shard'],symbol=n) for r,n in zip(rows,names) if any(t in n for t in terms)]
print(json.dumps(dict(functions_indexed=len(rows),shards_indexed=len(set(r['shard'] for r in rows)),scope='Symbol index search, not exhaustive function-body review',matches=selected),indent=2))
