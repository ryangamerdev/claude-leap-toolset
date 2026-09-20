#!/usr/bin/env python3
"""Live regression: Gameday must already be in Sideline with a zoomed field.

Reads the current UI without changing it. Exercises the signed server selected by
LEAP_BIN. Fails if visibility pruning loses the zoom reset and navigation controls.
"""
import importlib.util
import os

spec = importlib.util.spec_from_file_location('mcp_call', os.path.join(os.path.dirname(__file__), 'mcp-call.py'))
mcp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mcp)
client = mcp.Client([mcp.binary_path()])
try:
    reply = client.request('initialize', {'protocolVersion': '2025-06-18', 'capabilities': {},
                                       'clientInfo': {'name': 'gameday-zoom-regression', 'version': '1'}})
    assert 'result' in reply, reply
    client.notify('notifications/initialized')
    reply = client.request('tools/call', {'name': 'get_app_state', 'arguments': {
        'app': 'local.gameday.mac', 'disable_diff': True}})
    assert 'result' in reply and not reply['result'].get('isError'), reply
    state = '\n'.join(part.get('text', '') for part in reply['result'].get('content', []))
    print(state)
    for control in ['Reset field view', 'Next play', 'Show play information', 'Search plays']:
        assert control in state, f'Visible control lost from AX tree: {control}'
    print('PASS: zoomed Sideline controls remain discoverable')
finally:
    client.close()
