#!/usr/bin/env python3
"""Regression test MCP initialization and discovery using real client capabilities.

Usage: LEAP_BIN=/path/to/claude-leap python3 -B scripts/test-mcp-handshake.py
"""
import importlib.util
import os

spec = importlib.util.spec_from_file_location(
    "mcp_call", os.path.join(os.path.dirname(__file__), "mcp-call.py")
)
mcp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mcp)

cases = [
    {},
    {"roots": {"listChanged": True}},
    {"elicitation": {"form": {}, "url": {}},
     "experimental": {"codex/auth-change": {}}},
    {"experimental": {"object": {"nested": [1, True]}, "string": "supported",
                      "bool": True, "null": None, "array": [], "number": 1}},
]
for capabilities in cases:
    client = mcp.Client([mcp.binary_path()])
    try:
        reply = client.request("initialize", {
            "protocolVersion": "2025-06-18", "capabilities": capabilities,
            "clientInfo": {"name": "handshake-regression", "version": "1"},
        })
        assert "result" in reply, reply
        client.notify("notifications/initialized")
        reply = client.request("tools/list", {})
        tools = {tool["name"]: tool for tool in reply["result"]["tools"]}
        assert {"window", "embed"} <= tools["screenshot"]["inputSchema"]["properties"].keys()
        assert "Default FALSE" in tools["get_app_state"]["inputSchema"]["properties"]["include_screenshot"]["description"]
        reply = client.request("tools/call", {"name": "permissions", "arguments": {"prompt": False}})
        assert "result" in reply and not reply["result"].get("isError"), reply
        print(f"PASS: initialize, discover {len(tools)} tools, call permissions: {capabilities}")
    finally:
        client.close()
