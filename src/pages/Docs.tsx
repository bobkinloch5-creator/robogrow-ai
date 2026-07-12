import Navbar from "@/components/Navbar";
import { Card } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

const Docs = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      
      <div className="container mx-auto px-4 pt-24 pb-12 max-w-6xl">
        <h1 className="text-4xl font-bold mb-8">Documentation</h1>
        
        <Tabs defaultValue="getting-started" className="space-y-6">
          <TabsList className="bg-card border border-border">
            <TabsTrigger value="getting-started">Getting Started</TabsTrigger>
            <TabsTrigger value="plugin">Plugin Setup</TabsTrigger>
            <TabsTrigger value="prompts">Using Prompts</TabsTrigger>
            <TabsTrigger value="api">API Integration</TabsTrigger>
          </TabsList>

          <TabsContent value="getting-started">
            <Card className="bg-gradient-card p-8 border-border/50">
              <h2 className="text-3xl font-bold mb-6">Getting Started with Bloxsmith</h2>
              
              <div className="space-y-6">
                <section>
                  <h3 className="text-xl font-semibold mb-3">1. Create Your Account</h3>
                  <p className="text-muted-foreground">
                    Sign up for a free account at hideoutbot.lol. Bloxsmith is 100% free — no payment required.
                  </p>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">2. Install the Plugin</h3>
                  <p className="text-muted-foreground mb-2">
                    Download the single <code className="text-primary">Bloxsmith.lua</code> file from your
                    dashboard and add it as a Local Plugin in Roblox Studio:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4">
                    <li>Open Roblox Studio and go to the <strong>Plugins</strong> tab</li>
                    <li>Click <strong>Plugins Folder</strong> and drop <code className="text-primary">Bloxsmith.lua</code> inside</li>
                    <li>Or right-click the file in Studio and choose <strong>Save as Local Plugin</strong></li>
                    <li>Restart Studio if the button doesn't appear, then click <strong>Bloxsmith</strong> to open the panel</li>
                    <li>On your first request, click <strong>Allow</strong> when Studio asks for HTTP permission</li>
                  </ul>
                </section>


                <section>
                  <h3 className="text-xl font-semibold mb-3">3. Connect Your Account</h3>
                  <p className="text-muted-foreground">
                    Open the Bloxsmith plugin in Roblox Studio and sign in with your account credentials. This enables automatic synchronization between the website and Studio.
                  </p>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">4. Start Building</h3>
                  <p className="text-muted-foreground">
                    Enter your game idea in the plugin interface and watch as Bloxsmith creates your game automatically!
                  </p>
                </section>
              </div>
            </Card>
          </TabsContent>

          <TabsContent value="plugin">
            <Card className="bg-gradient-card p-8 border-border/50">
              <h2 className="text-3xl font-bold mb-6">Plugin Setup & Configuration</h2>
              
              <div className="space-y-6">
                <section>
                  <h3 className="text-xl font-semibold mb-3">System Requirements</h3>
                  <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4">
                    <li>Roblox Studio (latest version recommended)</li>
                    <li>Active internet connection</li>
                    <li>A free Bloxsmith account</li>
                  </ul>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Plugin Interface</h3>
                  <p className="text-muted-foreground mb-3">
                    The Bloxsmith plugin provides a clean interface with the following sections:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Account Status:</strong> Shows your email and prompt balance</li>
                    <li><strong>Game Builder:</strong> Input field for your game ideas</li>
                    <li><strong>History:</strong> View your recent prompts and generations</li>
                    <li><strong>Settings:</strong> Configure AI behavior and preferences</li>
                  </ul>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Troubleshooting</h3>
                  <p className="text-muted-foreground mb-2">
                    Common issues and solutions:
                  </p>
                  <div className="space-y-3">
                    <div className="p-4 bg-background/50 rounded-lg">
                      <h4 className="font-semibold mb-1">Plugin won't load</h4>
                      <p className="text-sm text-muted-foreground">
                        Ensure HTTP requests are enabled in Roblox Studio settings
                      </p>
                    </div>
                    <div className="p-4 bg-background/50 rounded-lg">
                      <h4 className="font-semibold mb-1">Can't sign in</h4>
                      <p className="text-sm text-muted-foreground">
                        Verify your credentials and check your internet connection
                      </p>
                    </div>
                    <div className="p-4 bg-background/50 rounded-lg">
                      <h4 className="font-semibold mb-1">Generation fails</h4>
                      <p className="text-sm text-muted-foreground">
                        Make sure your request is clear and try again
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
                    <li>Mention the game genre if applicable</li>
                    <li>Break complex features into multiple prompts</li>
                    <li>Reference existing parts of your game when modifying</li>
                  </ul>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Example Prompts</h3>
                  <div className="space-y-3">
                    <div className="p-4 bg-gradient-hero rounded-lg">
                      <h4 className="font-semibold mb-2">Creating a New Game</h4>
                      <code className="text-sm text-muted-foreground block">
                        "Create a zombie survival FPS with a shop system, different weapons, and wave-based gameplay"
                      </code>
                    </div>
                    <div className="p-4 bg-gradient-hero rounded-lg">
                      <h4 className="font-semibold mb-2">Adding Features</h4>
                      <code className="text-sm text-muted-foreground block">
                        "Add a leaderboard that tracks player kills and displays the top 10 players"
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
                    <li>Review AI-generated code before making new requests</li>
                  </ul>
                </section>
              </div>
            </Card>
          </TabsContent>

          <TabsContent value="api">
            <Card className="bg-gradient-card p-8 border-border/50">
              <h2 className="text-3xl font-bold mb-6">API Integration</h2>
              
              <div className="space-y-6">
                <section>
                  <h3 className="text-xl font-semibold mb-3">AI Engine</h3>
                  <p className="text-muted-foreground">
                    Bloxsmith is powered by NVIDIA-hosted GLM models for AI processing. Your requests are securely proxied through our backend so no API keys are ever exposed in the plugin.
                  </p>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Webhook Setup</h3>
                  <p className="text-muted-foreground mb-3">
                    Configure webhooks to receive real-time updates:
                  </p>
                  <div className="p-4 bg-background/50 rounded-lg font-mono text-sm">
                    <p className="text-muted-foreground">POST https://api.hideoutbot.lol/webhook</p>
                    <p className="text-muted-foreground mt-2">Headers:</p>
                    <p className="text-muted-foreground ml-4">Authorization: Bearer YOUR_API_KEY</p>
                  </div>
                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Rate Limits</h3>
                  <p className="text-muted-foreground">
                    Bloxsmith is free for everyone. Fair-use rate limits keep the service fast:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4">
                    <li>Generous free usage for all accounts</li>
                    <li>No credits, balances, or charges — ever</li>
                  </ul>

                </section>

                <section>
                  <h3 className="text-xl font-semibold mb-3">Security</h3>
                  <p className="text-muted-foreground">
                    All API communications are encrypted using TLS 1.3. API keys should never be shared or exposed in client-side code.
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
