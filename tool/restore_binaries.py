#!/usr/bin/env python3
"""Restore binary assets from tool/bin64 for the GitHub Actions checkout.

The GitHub file API used to mirror this repo stores those assets as base64
text. A local checkout already has the real files, so a missing tool/bin64
directory is a no-op.
"""

import base64
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parents[1]
src = root / "tool" / "bin64"
if not src.is_dir():
    print("tool/bin64 is absent; using files already in the tree")
    sys.exit(0)

count = 0
for path in sorted(src.rglob("*.b64")):
    rel = path.relative_to(src)
    dest = root / rel.with_suffix("")
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(base64.b64decode(path.read_text(encoding="ascii"), validate=True))
    count += 1
    print(f"restored {dest.relative_to(root)}")

if count == 0:
    raise SystemExit("tool/bin64 has no payloads")
