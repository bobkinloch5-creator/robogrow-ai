import Navbar from "@/components/Navbar";
import { Card } from "@/components/ui/card";

const Privacy = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      
      <div className="container mx-auto px-4 pt-24 pb-12 max-w-4xl">
        <h1 className="text-4xl font-bold mb-8">Privacy Policy</h1>
        
        <Card className="bg-gradient-card p-8 border-border/50">
          <div className="prose prose-invert max-w-none space-y-6">
            <section>
              <h2 className="text-2xl font-bold mb-4">Information We Collect</h2>
              <p className="text-muted-foreground mb-2">
                We collect information you provide directly to us:
              </p>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>Email address for account creation</li>
                <li>Payment information (processed securely by PayPal)</li>
                <li>Usage data and prompt history</li>
                <li>Games and content you create with our AI</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">How We Use Your Information</h2>
              <p className="text-muted-foreground">
                Your information is used to:
              </p>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>Provide and improve our services</li>
                <li>Process payments and manage your prompt balance</li>
                <li>Send service updates and important notifications</li>
                <li>Improve AI model performance</li>
                <li>Prevent fraud and abuse</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Data Security</h2>
              <p className="text-muted-foreground">
                We implement industry-standard security measures to protect your data. All sensitive data is encrypted both in transit and at rest. We use NVIDIA-hosted AI models for processing with enterprise-grade security.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Third-Party Services</h2>
              <p className="text-muted-foreground mb-2">
                We use the following third-party services:
              </p>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>PayPal for payment processing</li>
                <li>Amazon Bedrock for AI functionality</li>
                <li>Discord for community support</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Your Rights</h2>
              <p className="text-muted-foreground">
                You have the right to:
              </p>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>Access your personal data</li>
                <li>Request data deletion</li>
                <li>Export your data</li>
                <li>Opt-out of marketing communications</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Cookies</h2>
              <p className="text-muted-foreground">
                We use essential cookies to maintain your session and preferences. We do not use tracking cookies for advertising.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Children's Privacy</h2>
              <p className="text-muted-foreground">
                Our service is not intended for children under 13. We do not knowingly collect information from children under 13.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Changes to Privacy Policy</h2>
              <p className="text-muted-foreground">
                We may update this privacy policy from time to time. We will notify you of significant changes via email.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Contact Us</h2>
              <p className="text-muted-foreground">
                Questions about privacy? Contact us at privacy@hidebot.lol or through Discord.
              </p>
            </section>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default Privacy;
