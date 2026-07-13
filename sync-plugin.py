import os
import base64

HERE = os.path.dirname(os.path.abspath(__file__))
PLUGIN_PATH = os.path.join(HERE, "bloxsmith-plugin", "Bloxsmith.lua")
FUNCTION_PATH = os.path.join(HERE, "supabase", "functions", "download-plugin", "index.ts")

def main():
    if not os.path.exists(PLUGIN_PATH):
        print(f"Error: Plugin file not found at {PLUGIN_PATH}")
        return

    if not os.path.exists(FUNCTION_PATH):
        print(f"Error: Function file not found at {FUNCTION_PATH}")
        return

    # Read the plugin source
    with open(PLUGIN_PATH, "rb") as fh:
        plugin_bytes = fh.read()

    encoded = base64.b64encode(plugin_bytes).decode("utf-8")
    print(f"Bundled plugin size: {len(plugin_bytes)} bytes")
    print(f"Base64 encoded size: {len(encoded)} chars")

    # Read the download-plugin index.ts
    with open(FUNCTION_PATH, "r", encoding="utf-8-sig") as fh:
        lines = fh.readlines()

    # Find the line defining PLUGIN_B64
    found = False
    for i, line in enumerate(lines):
        if line.strip().startswith("const PLUGIN_B64 ="):
            lines[i] = f'const PLUGIN_B64 = "{encoded}";\n'
            found = True
            break

    if not found:
        print("Error: Could not find 'const PLUGIN_B64 =' line in index.ts")
        return

    # Write the updated file back
    with open(FUNCTION_PATH, "w", encoding="utf-8-sig") as fh:
        fh.writelines(lines)


    print("Successfully synchronized plugin with Supabase download-plugin function.")

if __name__ == "__main__":
    main()
