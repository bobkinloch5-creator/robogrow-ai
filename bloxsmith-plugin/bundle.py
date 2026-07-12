#!/usr/bin/env python3
"""
bundle.py — Combine the modular Bloxsmith plugin (src/) into a single
self-contained Bloxsmith.lua file that can be saved directly as a Local Plugin
in Roblox Studio (no Rojo required).

It wraps every ModuleScript in a virtual module registry and rewrites every
`require(script...)` call to resolve against that registry.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")
OUT = os.path.join(HERE, "Bloxsmith.lua")

REQUIRE_RE = re.compile(r"require\(script((?:\.[A-Za-z_][A-Za-z0-9_]*)*)\)")


def module_id(rel_path: str) -> str:
    no_ext = rel_path[:-4] if rel_path.endswith(".lua") else rel_path
    return no_ext.replace(os.sep, ".")


def resolve(current_parts, chain: str) -> str:
    cur = list(current_parts)
    for tok in [t for t in chain.split(".") if t]:
        if tok == "Parent":
            if cur:
                cur.pop()
        else:
            cur.append(tok)
    return ".".join(cur)


def rewrite_requires(source: str, current_parts) -> str:
    def repl(m):
        return '_R("%s")' % resolve(current_parts, m.group(1))
    return REQUIRE_RE.sub(repl, source)


def main():
    modules = {}          # id -> rewritten source
    init_source = None

    for root, _dirs, files in os.walk(SRC):
        for fname in sorted(files):
            if not fname.endswith(".lua"):
                continue
            abs_path = os.path.join(root, fname)
            rel = os.path.relpath(abs_path, SRC)
            with open(abs_path, "r", encoding="utf-8") as fh:
                src = fh.read()

            if fname == "init.server.lua":
                init_source = rewrite_requires(src, [])
                continue

            mid = module_id(rel)
            parts = mid.split(".")
            modules[mid] = rewrite_requires(src, parts)

    if init_source is None:
        print("ERROR: init.server.lua not found", file=sys.stderr)
        sys.exit(1)

    out = []
    out.append("--[[")
    out.append("\tBloxsmith — AI Copilot for Roblox Studio (single-file build)")
    out.append("\tGenerated from src/ by bundle.py. Save this as a Local Plugin in Studio.")
    out.append("\tPlugins tab -> right-click this file -> Save as Local Plugin, or drop it")
    out.append("\tinto your Plugins Folder. No Rojo required.")
    out.append("")
    out.append("\tCopyright (c) Bloxsmith. All rights reserved.")
    out.append("\tThis plugin and its source code are the exclusive property of Bloxsmith and are")
    out.append("\tprotected by copyright law. Unauthorized copying, redistribution, resale, or")
    out.append("\treproduction of any part of this software is strictly prohibited. Bloxsmith is")
    out.append("\tnot affiliated with or endorsed by Roblox Corporation. See https://www.bloxsmiths.xyz")
    out.append("]]")
    out.append("")
    out.append("local _modules = {}")
    out.append("local _cache = {}")
    out.append("local function _R(name)")
    out.append("\tlocal cached = _cache[name]")
    out.append("\tif cached ~= nil then return cached.value end")
    out.append("\tlocal factory = _modules[name]")
    out.append('\tif not factory then error("[Bloxsmith] module not found: " .. tostring(name)) end')
    out.append("\tlocal value = factory()")
    out.append("\t_cache[name] = { value = value }")
    out.append("\treturn value")
    out.append("end")
    out.append("")

    for mid in sorted(modules):
        out.append('_modules["%s"] = function()' % mid)
        out.append(modules[mid].rstrip("\n"))
        out.append("end")
        out.append("")

    out.append("-- ===== Plugin bootstrap (init.server) =====")
    out.append(init_source.rstrip("\n"))
    out.append("")

    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))

    print("Wrote %s (%d modules)" % (OUT, len(modules)))


if __name__ == "__main__":
    main()
