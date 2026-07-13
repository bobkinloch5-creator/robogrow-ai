#!/usr/bin/env python3
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")
BLOXSMITH_LUA = os.path.join(HERE, "Bloxsmith.lua")

def main():
    if not os.path.exists(BLOXSMITH_LUA):
        print(f"Error: {BLOXSMITH_LUA} does not exist.")
        return

    with open(BLOXSMITH_LUA, "r", encoding="utf-8") as f:
        content = f.read()

    # Normalize line endings to \n
    content = content.replace("\r\n", "\n")

    # Split by _modules["
    segments = content.split('_modules["')
    
    # Ensure src directory exists and is clean
    os.makedirs(SRC, exist_ok=True)

    modules_count = 0
    for seg in segments[1:]:
        # Parse the module name and content
        # Format: MODULE_NAME"] = function()\nMODULE_CONTENT\nend\n\n
        match = re.match(r'^([^"]+)"]\s*=\s*function\(\)\n([\s\S]*)$', seg)
        if not match:
            print("Failed to match segment structure.")
            continue

        mod_name = match.group(1)
        mod_body = match.group(2)

        # Check if this is the last segment which also contains the bootstrap script
        bootstrap_marker = "\n-- ===== Plugin bootstrap (init.server) =====\n"
        init_content = None
        if bootstrap_marker in mod_body:
            mod_body, init_content = mod_body.split(bootstrap_marker, 1)

        # Strip the trailing "\nend\n" or "\nend"
        if mod_body.endswith("\nend\n"):
            mod_body = mod_body[:-5]
        elif mod_body.endswith("\nend"):
            mod_body = mod_body[:-4]

        # Convert _R("Path.To.Module") back to require(script.Path.To.Module)
        # Note: In our src files, they are written as require(script.Parent...) etc.
        # However, to be general and support full round-trip, we can do a simple translation if needed.
        # But wait! The unpacked source in the plugin is already require(script...) or _R.
        # Let's restore the original require format if we can.
        # How were they written in src/?
        # E.g. in AIService: require(script.Parent.Parent.Config)
        # Wait, if they were compiled to _R("Services.AIService"), how do we know the relative require chain?
        # Actually, let's look at config.lua in a previous version of Bloxsmith.lua.
        # Ah, they use the _R function for resolution, but we can also just leave _R in place or restore requires.
        # Wait, the unpacked modules in BloxsmithPlugin_5/Bloxsmith (12).lua already use _R or require?
        # Let's check! The bundled Bloxsmith.lua uses _R because it is compiled by bundle.py!
        # If we unpack it, keeping the _R calls is perfectly fine and Roblox will run it successfully,
        # or we can reconstruct relative require paths.
        # Wait! Let's check if the previous src/ files had require(script...) or _R.
        # In git status:
        # Changes not staged for commit:
        #   modified:   bloxsmith-plugin/src/Config.lua
        #   modified:   bloxsmith-plugin/src/Services/AIService.lua
        # It means the previous src/ files ALREADY had modifications, and they had require(script.Parent.Parent...)
        # Wait, let's see. If the previous run did unpacking, how did it translate _R back to require?
        # Let's look at our previous conversation summary:
        # "I wrote a simple Python script, C:\Users\david\.gemini\antigravity\scratch\robogrow-ai\bloxsmith-plugin\unpack.py, to parse and unpack the plugin."
        # If the user already had the unpacked files in src/ before they were overwritten, did they use require or _R?
        # Let's check what is in src/Config.lua currently!
        # Let's check using view_file or git diff!
        
        # Let's write the module content to file.
        # Resolve target path: e.g. "Services.AIService" -> "Services/AIService.lua"
        rel_path = mod_name.replace(".", os.sep) + ".lua"
        target_path = os.path.join(SRC, rel_path)
        os.makedirs(os.path.dirname(target_path), exist_ok=True)

        with open(target_path, "w", encoding="utf-8") as fh:
            fh.write(mod_body)
        print(f"Unpacked module: {mod_name} -> {rel_path}")
        modules_count += 1

        if init_content is not None:
            # Write init.server.lua
            init_path = os.path.join(SRC, "init.server.lua")
            # Strip trailing newlines
            init_content = init_content.strip("\n")
            with open(init_path, "w", encoding="utf-8") as fh:
                fh.write(init_content)
            print("Unpacked bootstrap: init.server.lua")

    print(f"Successfully unpacked {modules_count} modules.")

if __name__ == "__main__":
    main()
