import Navbar from "@/components/Navbar";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { MessageCircle } from "lucide-react";

const DISCORD_URL = "https://discord.gg/gkYGrVBbca";
const LAST_UPDATED = "July 12, 2026";

const Privacy = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      <div className="container mx-auto px-4 pt-24 pb-12 max-w-4xl">
        <h1 className="text-4xl font-bold mb-2">Privacy Policy</h1>
        <p className="text-sm text-muted-foreground mb-8">Last updated: {LAST_UPDATED}</p>

        <Card className="bg-gradient-card p-8 border-border/50">
          <div className="prose prose-invert max-w-none space-y-6">
            <section>
              <p className="text-muted-foreground">
                This Privacy Policy explains how Bloxsmith ("we", "us", or "our") collects, uses, and
                protects your information when you use the Bloxsmith website at bloxsmiths.xyz and the
                Bloxsmith Roblox Studio plugin (together, the "Service").
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">1. Information We Collect</h2>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>Account information such as your email address</li>
                <li>Usage data, including feature usage</li>
                <li>Prompts you send and the code/content the AI generates for you</li>
                <li>Basic project context the plugin sends to fulfil a request (e.g. selected scripts and hierarchy)</li>

              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">2. How We Use Your Information</h2>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>To provide, maintain, and improve the Service</li>

                <li>To generate AI responses for your requests</li>
                <li>To send important service notifications</li>
                <li>To detect, prevent, and address fraud and abuse</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">3. Plugin Data & Your Code</h2>
              <p className="text-muted-foreground">
                The Bloxsmith plugin only sends the context needed to complete a request you make. Your
                code is used to generate a response and is not sold. The plugin never stores AI provider
                keys on your machine — requests are proxied through our secure backend.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">4. Data Security</h2>
              <p className="text-muted-foreground">
                We use industry-standard security measures. Data is encrypted in transit and at rest, and
                AI processing is performed by enterprise-grade, NVIDIA-hosted models.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">5. Third-Party Services</h2>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>NVIDIA-hosted AI models for AI functionality</li>
                <li>Discord for community and support</li>

              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">6. Your Rights</h2>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>Access the personal data we hold about you</li>
                <li>Request correction or deletion of your data</li>
                <li>Export your data</li>
                <li>Opt out of non-essential communications</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">7. Cookies</h2>
              <p className="text-muted-foreground">
                We use essential cookies to keep you signed in and remember preferences. We do not use
                tracking cookies for advertising.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">8. Children's Privacy</h2>
              <p className="text-muted-foreground">
                The Service is not directed at children under 13, and we do not knowingly collect their
                personal information.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">9. Changes to This Policy</h2>
              <p className="text-muted-foreground">
                We may update this policy from time to time. Significant changes will be announced on our
                website or via email.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">10. Contact Us</h2>
              <p className="text-muted-foreground mb-4">
                Questions about privacy? Email privacy@bloxsmiths.xyz or reach us on Discord.
              </p>
              <a href={DISCORD_URL} target="_blank" rel="noopener noreferrer">
                <Button className="bg-gradient-primary shadow-glow">
                  <MessageCircle className="mr-2 h-4 w-4" /> Join our Discord
                </Button>
              </a>
            </section>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default Privacy;
