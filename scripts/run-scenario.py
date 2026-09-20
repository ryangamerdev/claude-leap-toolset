#!/usr/bin/env python3
"""Execute a reviewed Leap intent scenario through stdio MCP; not a native host acceptance claim.
Usage: run-scenario.py scenario.json --output artifacts/test-runs/<run>/result.json
Scenario: {session: {project,app,backend,window?,endpoint?}, steps: [...], timeout?:60}.
No implicit reset or retry. A run passes only with completed execution and passed assertions.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('leap_mcp_client', ROOT/'scripts/mcp-call.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

def invoke(client, name, arguments):
    response=client.request('tools/call', {'name':name,'arguments':arguments}, timeout=180)
    if 'error' in response or response.get('result',{}).get('isError'):
        raise RuntimeError(json.dumps(response))
    text=next(c['text'] for c in response['result']['content'] if c['type']=='text')
    return json.loads(text)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('scenario',type=Path)
    parser.add_argument('--output',required=True,type=Path)
    args=parser.parse_args()
    output=args.output.resolve()
    if not output.is_relative_to(ROOT): parser.error('Keep run output within the repository')
    scenario=json.loads(args.scenario.read_text())
    client=module.Client([module.binary_path()])
    result={'execution':'failed','verification':'unknown'}
    session=None
    try:
        client.request('initialize',{'protocolVersion':'2024-11-05','capabilities':{},'clientInfo':{'name':'leap-scenario','version':'2'}})
        client.notify('notifications/initialized')
        session=invoke(client,'session_open',scenario['session'])['session_id']
        result=invoke(client,'ui_perform',{'session_id':session,'steps':scenario['steps'],'timeout':scenario.get('timeout',60)})
        if result.get('omittedFromResponse'):
            result=json.loads(Path(result['file']).read_text())
    except Exception as error:
        result['error']=str(error)
    finally:
        if session:
            try: invoke(client,'session_close',{'session_id':session})
            except Exception as error: result['close_error']=str(error)
        client.close()
        output.parent.mkdir(parents=True,exist_ok=True)
        output.write_text(json.dumps(result,indent=2))
    print(json.dumps({'execution':result['execution'],'verification':result['verification'],'file':str(output)}))
    return 0 if result['execution']=='completed' and result['verification']=='passed' else 1

if __name__=='__main__': sys.exit(main())
