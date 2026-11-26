#!/usr/bin/env python3
"""Stamp a built plugin bundle's plugin.json with Mattermore's version and name.

Usage: stamp-plugin.py <plugin.json> <version> <name>

The plugin id is deliberately left alone: a Mattermore bundle is a drop-in
replacement for the official plugin, so existing settings and data survive the
swap.
"""

import json
import sys

path, version, name = sys.argv[1], sys.argv[2], sys.argv[3]

with open(path) as fh:
    manifest = json.load(fh)

manifest["version"] = version
manifest["name"] = name
manifest["homepage_url"] = "https://mattermore.dev"
manifest["support_url"] = "https://github.com/dennisklappe/mattermore/issues"

with open(path, "w") as fh:
    json.dump(manifest, fh, indent=4)
    fh.write("\n")

print(f"    stamped {version}")
