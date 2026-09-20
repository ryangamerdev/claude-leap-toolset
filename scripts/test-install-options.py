#!/usr/bin/env python3
"""Verify installer argument handling cannot trigger mutations for help/bad options."""
import importlib.util
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("leap_install", Path(__file__).with_name("install.py"))
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)
for args, expected in [(["--help"], 0), (["--unknown"], 2), (["--uninstall", "--skills-only"], 2)]:
    with patch.object(installer.sys, "argv", ["install.py", *args]), patch.object(installer, "install_app") as app, patch.object(installer, "install_skills") as skills, patch.object(installer, "run") as run, patch.object(installer, "_rm") as remove:
        try:
            installer.main()
        except SystemExit as error:
            assert error.code == expected, (args, error.code)
        else:
            raise AssertionError(f"Expected parser exit: {args}")
        for operation in (app, skills, run, remove):
            operation.assert_not_called()
print("PASS: help, unknown and conflicting options have no installer side effects")
