import Navbar from "@/components/Navbar";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { MessageCircle } from "lucide-react";

const DISCORD_URL = "https://discord.gg/gkYGrVBbca";
const LAST_UPDATED = "July 12, 2026";

const Terms = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      <div className="container mx-auto px-4 pt-24 pb-12 max-w-4xl">
        <h1 className="text-4xl font-bold mb-2">Terms of Service</h1>
        <p className="text-sm text-muted-foreground mb-8">Last updated: {LAST_UPDATED}</p>

        <Card className="bg-gradient-card p-8 border-border/50">
          <div className="prose prose-invert max-w-none space-y-6">
            <section>
              <h2 className="text-2xl font-bold mb-4">1. Acceptance of Terms</h2>
              <p className="text-muted-foreground">
                By accessing or using Bloxsmith (the website at hideoutbot.lol and the Bloxsmith Roblox
                Studio plugin, together the "Service"), you agree to be bound by these Terms of Service. If
                you do not agree, do not use the Service.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">2. Use License</h2>
              <p className="text-muted-foreground">
                We grant you a personal, non-exclusive, non-transferable license to use Bloxsmith for both
                personal and commercial Roblox game development. This license terminates automatically if you
                breach these Terms.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">3. Accounts</h2>
              <p className="text-muted-foreground">
                You are responsible for keeping your account credentials secure and for all activity under
                your account. Notify us immediately of any unauthorized use.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">4. Free Service</h2>
              <p className="text-muted-foreground">
                Bloxsmith is provided free of charge. There are no fees, subscriptions, or credits to
                purchase. We may apply reasonable fair-use limits to keep the Service reliable for everyone.
              </p>

            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">5. Your Content</h2>
              <p className="text-muted-foreground">
                You retain all rights to the games and content you create with Bloxsmith. We do not claim
                ownership of your creations and you are free to monetize and publish them on Roblox.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">6. AI-Generated Content</h2>
              <p className="text-muted-foreground">
                AI output is provided "as is". While we aim for high quality, we cannot guarantee it is
                error-free, secure, or fit for a particular purpose. You are responsible for reviewing,
                testing, and validating all generated code before shipping it.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">7. Acceptable Use</h2>
              <p className="text-muted-foreground">
                You may not abuse the Service, attempt to reverse engineer or resell it, generate malicious
                or exploitative content, or violate the Roblox Terms of Use or applicable law.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">8. Service Availability</h2>
              <p className="text-muted-foreground">
                We strive for high uptime but do not guarantee uninterrupted service. Features may change,
                and maintenance will be announced in advance where possible.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">9. Limitation of Liability</h2>
              <p className="text-muted-foreground">
                To the maximum extent permitted by law, Bloxsmith is not liable for any indirect, incidental,
                special, consequential, or punitive damages arising from your use of the Service.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">10. Changes to These Terms</h2>
              <p className="text-muted-foreground">
                We may modify these Terms at any time. Continued use of the Service after changes take effect
                constitutes acceptance of the updated Terms.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">11. Contact</h2>
              <p className="text-muted-foreground mb-4">
                Questions about these Terms? Email support@hideoutbot.lol or join our Discord.
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

export default Terms;
