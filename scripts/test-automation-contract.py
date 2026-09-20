#!/usr/bin/env python3
"""Protocol/adapter fault fixture, NOT native application acceptance. No real UI input.
Run with LEAP_BIN pointing at signed candidate. Artifacts remain in repository.
"""
import importlib.util
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import threading

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('scenario',ROOT/'scripts/run-scenario.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
OUT=ROOT/'artifacts/test-runs/20260920-rebuild'
fixture=OUT/'fixtures/contract';fixture.mkdir(parents=True,exist_ok=True)
# git boundary avoids sharing the live campaign writer or changing parent store.
import subprocess
subprocess.run(['git','init','-q',str(fixture)],check=True)
state={'clicks':0,'label':'Save'}
class Handler(BaseHTTPRequestHandler):
    def log_message(self,*args): pass
    def do_GET(self): self.reply()
    def do_POST(self):
        self.body=json.loads(self.rfile.read(int(self.headers.get('Content-Length','0'))) or b'{}')
        self.reply()
    def reply(self):
        status=200
        if self.path=='/session': value={'sessionId':'fixture'}
        elif self.path.endswith('/wda/device/info'):value={'uuid':'fixture-device'}
        elif self.path.endswith('/wda/activeAppInfo'):value={'bundleId':'fixture.app'}
        elif self.path.endswith('/orientation'):value='PORTRAIT'
        elif self.path.endswith('/source?format=json'):
            value={'type':'Application','rect':{'x':0,'y':0,'width':800,'height':600},'children':[{'type':'Button','rawIdentifier':'save','label':state['label'],'isEnabled':'1','rect':{'x':100,'y':100,'width':50,'height':30}}]}
        elif self.path.endswith('/elements'):value=[{'ELEMENT':'save'}]
        elif self.path.endswith('/element/save/click'):
            state['clicks']+=1;state['label']='Saved';status=500;value={'error':'unknown error','message':'Injected lost acknowledgement after app effect'}
        elif self.path.endswith('/screenshot'):value='aW1hZ2U='
        else:status=404;value={'error':'unknown command','message':self.path}
        body=json.dumps({'value':value}).encode()
        self.send_response(status);self.send_header('Content-Type','application/json');self.send_header('Content-Length',str(len(body)));self.end_headers();self.wfile.write(body)
server=ThreadingHTTPServer(('127.0.0.1',0),Handler)
threading.Thread(target=server.serve_forever,daemon=True).start()
client=m.module.Client([m.module.binary_path()])
try:
    client.request('initialize',{'protocolVersion':'2024-11-05','capabilities':{},'clientInfo':{'name':'contract-fixture','version':'2'}});client.notify('notifications/initialized')
    opened=m.invoke(client,'session_open',{'project':str(fixture),'app':'fixture.app','backend':'wda','endpoint':f'http://127.0.0.1:{server.server_port}'})
    sid=opened['session_id']
    noinput=m.invoke(client,'ui_perform',{'session_id':sid,'steps':[{'type':'assert','expect':{'selector':{'label':'Missing'},'condition':'exists'}},{'type':'action','action':'click','selector':{'identifier':'save'}}]})
    assert state['clicks']==0 and noinput['verification']=='failed' and noinput['steps'][1]['execution']=='skipped',noinput
    rejected=False
    try:
        m.invoke(client,'ui_perform',{'session_id':sid,'steps':[{'type':'action','action':'click','selector':{'identifier':'save'}},{'type':'action','action':'click','selector':{'identifier':'save'},'arguments':{'modifiers':'shift'}}]})
    except RuntimeError:
        rejected=True
    assert rejected and state['clicks']==0, 'Unsupported later step must prevent earlier input'
    result=m.invoke(client,'ui_perform',{'session_id':sid,'steps':[{'type':'action','action':'click','selector':{'identifier':'save'},'expect':{'selector':{'label':'Saved'},'condition':'exists'}},{'type':'action','action':'click','selector':{'identifier':'save'}}]})
    assert state['clicks']==1,result
    assert result['steps'][0]['dispatch']=='uncertain' and result['steps'][1]['execution']=='skipped',result
    history=m.invoke(client,'session_history',{'session_id':sid})
    assert len(history['items'])==2,history
    snapshot=m.invoke(client,'ui_observe',{'session_id':sid,'snapshot':opened['snapshot'],'selector':{'identifier':'save'}})
    assert snapshot['items'][0]['label']=='Save',snapshot
    output={'evidenceType':'protocol fixture, not native acceptance','assertionFailure':noinput,'ambiguousInput':result,'history':history,'historicalSnapshot':snapshot,'clicks':state['clicks'],'unsupportedArgumentPrevalidation':rejected}
    (OUT/'contract-results.json').write_text(json.dumps(output,indent=2))
    print('PASS: failed assertion stops writes; ambiguous effect dispatches once; skipped follow-up; retained history and immutable snapshot')
finally:
    client.close();server.shutdown()
