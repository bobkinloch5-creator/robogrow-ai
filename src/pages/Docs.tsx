import Navbar from "@/components/Navbar";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Download, Puzzle } from "lucide-react";

const PLUGIN_VERSION = "3.18.1";
const pluginDownloadUrl = `/Bloxsmith.lua?v=${PLUGIN_VERSION}`;

const Docs = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      <div className="container mx-auto px-4 pt-24 pb-12 max-w-6xl">
        <h1 className="text-4xl font-bold mb-2">Documentation</h1>
        <p className="text-muted-foreground mb-8">
          Everything you need to install Bloxsmith and start building — no account, 100% free.
        </p>

        {/* Download callout */}
        <Card className="bg-gradient-hero p-8 border-border/50 shadow-elegant mb-8 relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-glow animate-pulse-glow" />
          <div className="relative z-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full border border-border bg-card/60 px-3 py-1 text-xs text-muted-foreground backdrop-blur-sm mb-3">
                <Puzzle className="h-3.5 w-3.5 text-primary" />
                Single-file plugin — no Rojo required
              </div>
              <h2 className="text-2xl font-bold mb-1">Download Bloxsmith for Roblox Studio</h2>
              <p className="text-muted-foreground max-w-xl">
                Grab the <code className="text-primary">Bloxsmith.lua</code> file and save it as a
                Local Plugin. That's it — you're ready to build.
              </p>
            </div>
            <a href={pluginDownloadUrl} download="Bloxsmith.lua" className="shrink-0">
              <Button size="lg" className="bg-gradient-primary shadow-glow text-lg px-8 h-14">
                <Download className="mr-2 h-5 w-5" />
                Download Plugin (.lua)
              </Button>
            </a>
          </div>
        </Card>

        <Tabs defaultValue="getting-started" className="space-y-6">
          <TabsList className="bg-card border border-border">
            <TabsTrigger value="getting-started">Getting Started</TabsTrigger>
            <TabsTrigger value="plugin">Plugin Setup</TabsTrigger>
            <TabsTrigger value="prompts">Using Prompts</TabsTrigger>
            <TabsTrigger value="capabilities">What It Can Build</TabsTrigger>
          </TabsList>

          <TabsContent value="getting-started">
            <Card className="bg-gradient-card p-8 border-border/50">
              <h2 className="text-3xl font-bold mb-6">Getting Started with Bloxsmith</h2>

              <div className="space-y-6">
                <section>
                  <h3 className="text-xl font-semibold mb-3">1. Download the Plugin</h3>
                  <p className="text-muted-foreground mb-3">
                    Click the download button above to get{" "}
                    <code className="text-primary">Bloxsmith.lua</code>. No account or sign-up
                    needed — Bloxsmith is completely free.
                  </p>
                  <a href={pluginDownloadUrl} download="Bloxsmith.lua">
                    <Button variant="outline">
                      <Download className="mr-2 h-4 w-4" />
                      Download Bloxsmith.lua
                    </Button>
                  </a>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">2. Install as a Local Plugin</h3>
                  <p className="text-muted-foreground mb-2">
                    Add the file to Roblox Studio in one of two ways:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4">
                    <li>
                      In Studio, open the <strong>Plugins</strong> tab and click{" "}
                      <strong>Plugins Folder</strong>, then drop{" "}
                      <code className="text-primary">Bloxsmith.lua</code> inside
                    </li>
                    <li>
                      Or right-click <code className="text-primary">Bloxsmith.lua</code> on your
                      computer, open it with Studio, and choose{" "}
                      <strong>Save as Local Plugin</strong>
                    </li>
                    <li>Restart Studio if the Bloxsmith button doesn't appear right away</li>
                  </ul>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">3. Open Bloxsmith</h3>
                  <p className="text-muted-foreground">
                    Click the <strong>Bloxsmith</strong> button in the Plugins tab to open the
                    panel. On your first request, click <strong>Allow</strong> when Studio asks for
                    HTTP permission — this lets the plugin talk to the AI.
                  </p>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">4. Start Building</h3>
                  <p className="text-muted-foreground">
                    Type what you want to build (e.g. "build an inventory system with a UI"), then
                    review the generated code and instances and click <strong>Insert</strong> to add
                    them to your game. Every change is undoable with Ctrl+Z.
                  </p>
                </section>
              </div>
            </Card>
          </TabsContent>

          <TabsContent value="plugin">
            <Card className="bg-gradient-card p-8 border-border/50">
              <h2 className="text-3xl font-bold mb-6">Plugin Setup &amp; Configuration</h2>

              <div className="space-y-6">
                <section>
                  <h3 className="text-xl font-semibold mb-3">System Requirements</h3>
                  <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4">
                    <li>Roblox Studio (latest version recommended)</li>
                    <li>An active internet connection</li>
                    <li>HTTP requests allowed when prompted (first run)</li>
                  </ul>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Plugin Interface</h3>
                  <p className="text-muted-foreground mb-3">
                    The Bloxsmith panel gives you everything in one place:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Prompt box:</strong> Describe what you want to build or fix</li>
                    <li><strong>Review &amp; Insert:</strong> Preview generated code/instances before applying</li>
                    <li><strong>Modes:</strong> Generate, fix, optimize, explain, and full agent build</li>
                    <li><strong>Undo/Redo:</strong> Every change is a single Ctrl+Z waypoint</li>
                  </ul>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Troubleshooting</h3>
                  <div className="space-y-3">
                    <div className="p-4 bg-background/50 rounded-lg">
                      <h4 className="font-semibold mb-1">Plugin button doesn't appear</h4>
                      <p className="text-sm text-muted-foreground">
                        Restart Roblox Studio after saving the local plugin, then check the Plugins tab.
                      </p>
                    </div>
                    <div className="p-4 bg-background/50 rounded-lg">
                      <h4 className="font-semibold mb-1">Requests fail or time out</h4>
                      <p className="text-sm text-muted-foreground">
                        Make sure you clicked <strong>Allow</strong> for HTTP access and that your
                        internet connection is working.
                      </p>
                    </div>
                    <div className="p-4 bg-background/50 rounded-lg">
                      <h4 className="font-semibold mb-1">Generation isn't what you expected</h4>
                      <p className="text-sm text-muted-foreground">
                        Be more specific in your prompt, or refine it step by step. See the
                        "Using Prompts" tab for tips.
                      </p>
                    </div>
                    <div className="p-4 bg-background/50 rounded-lg">
                      <h4 className="font-semibold mb-1">Still stuck?</h4>
                      <p className="text-sm text-muted-foreground">
                        Join our{" "}
                        <a
                          href="https://discord.gg/gkYGrVBbca"
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-primary hover:underline"
                        >
                          Discord community
                        </a>{" "}
                        for live help.
                      </p>
                    </div>
                  </div>
                </section>
              </div>
            </Card>
          </TabsContent>

          <TabsContent value="prompts">
            <Card className="bg-gradient-card p-8 border-border/50">
              <h2 className="text-3xl font-bold mb-6">Using Prompts Effectively</h2>

              <div className="space-y-6">
                <section>
                  <h3 className="text-xl font-semibold mb-3">Prompt Best Practices</h3>
                  <p className="text-muted-foreground mb-3">
                    Get the best results by following these guidelines:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li>Be specific about what you want</li>
                    <li>Mention the game genre or style if applicable</li>
                    <li>Break complex features into multiple prompts</li>
                    <li>Reference existing parts of your game when modifying</li>
                  </ul>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Example Prompts</h3>
                  <div className="space-y-3">
                    <div className="p-4 bg-gradient-hero rounded-lg">
                      <h4 className="font-semibold mb-2">Building a UI</h4>
                      <code className="text-sm text-muted-foreground block">
                        "Build a main menu ScreenGui with a centered panel, Play and Settings buttons, rounded corners, and a gradient background"
                      </code>
                    </div>
                    <div className="p-4 bg-gradient-hero rounded-lg">
                      <h4 className="font-semibold mb-2">Creating a System</h4>
                      <code className="text-sm text-muted-foreground block">
                        "Create a shop system with a UI, buy buttons, and a server script that handles purchases and currency"
                      </code>
                    </div>
                    <div className="p-4 bg-gradient-hero rounded-lg">
                      <h4 className="font-semibold mb-2">Modifying Existing Content</h4>
                      <code className="text-sm text-muted-foreground block">
                        "Make the zombies faster and add boss zombies every 5 waves with 3x health"
                      </code>
                    </div>
                  </div>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Prompt Efficiency Tips</h3>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li>Use iterative refinement instead of starting over</li>
                    <li>Group related features in a single prompt when possible</li>
                    <li>Save successful prompts for reference</li>
                    <li>Review AI-generated changes before applying them</li>
                  </ul>
                </section>
              </div>
            </Card>
          </TabsContent>

          <TabsContent value="capabilities">
            <Card className="bg-gradient-card p-8 border-border/50">
              <h2 className="text-3xl font-bold mb-6">What Bloxsmith Can Build</h2>

              <div className="space-y-6">
                <section>
                  <h3 className="text-xl font-semibold mb-3">AI Engine</h3>
                  <p className="text-muted-foreground">
                    Bloxsmith is powered by NVIDIA-hosted GLM models. Your requests are securely
                    proxied through our backend, so no API keys are ever stored in or exposed by the
                    plugin.
                  </p>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Anything in Roblox</h3>
                  <p className="text-muted-foreground mb-3">
                    Bloxsmith can create virtually any Roblox instance and wire it up with Luau:
                  </p>
                  <div className="grid sm:grid-cols-2 gap-3">
                    {[
                      "Full GUIs, menus, HUDs & shops",
                      "Parts, models, maps & builds",
                      "Lighting, particles, beams & effects",
                      "Sounds & ambient audio",
                      "Complete game systems (inventory, quests, combat)",
                      "RemoteEvents, tools, NPCs & vehicles",
                      "Fixes, optimizations & refactors",
                      "Security & performance analysis",
                    ].map((item) => (
                      <div key={item} className="p-3 bg-background/50 rounded-lg text-sm text-muted-foreground">
                        {item}
                      </div>
                    ))}
                  </div>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Safe by Design</h3>
                  <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4">
                    <li>Every change is a single undoable Ctrl+Z waypoint</li>
                    <li>You review generated code and instances before they're applied</li>
                    <li>Server-side input validation is generated for multiplayer safety</li>
                  </ul>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Pricing</h3>
                  <p className="text-muted-foreground">
                    Bloxsmith is 100% free for everyone. There are no accounts, credits, balances, or
                    charges — ever. Fair-use rate limits keep the service fast for the whole community.
                  </p>
                </section>
              </div>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default Docs;
