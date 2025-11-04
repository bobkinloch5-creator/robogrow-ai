import Navbar from "@/components/Navbar";
import { Card } from "@/components/ui/card";

const Refund = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      
      <div className="container mx-auto px-4 pt-24 pb-12 max-w-4xl">
        <h1 className="text-4xl font-bold mb-8">Refund Policy</h1>
        
        <Card className="bg-gradient-card p-8 border-border/50">
          <div className="prose prose-invert max-w-none space-y-6">
            <section>
              <h2 className="text-2xl font-bold mb-4">General Policy</h2>
              <p className="text-muted-foreground">
                We strive for customer satisfaction. Our refund policy is designed to be fair while preventing abuse of our AI services.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Eligible for Refund</h2>
              <p className="text-muted-foreground mb-2">
                Refunds may be issued in the following cases:
              </p>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>Technical issues preventing service access within 48 hours of purchase</li>
                <li>Duplicate charges</li>
                <li>Purchase made in error (within 24 hours, before any prompts are used)</li>
                <li>Service outage lasting more than 72 hours affecting your account</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Not Eligible for Refund</h2>
              <p className="text-muted-foreground mb-2">
                The following situations are not eligible for refunds:
              </p>
              <ul className="list-disc list-inside text-muted-foreground space-y-1">
                <li>After prompts have been used</li>
                <li>Changes in personal circumstances or game plans</li>
                <li>Dissatisfaction with AI-generated content quality (due to subjective nature)</li>
                <li>Violation of Terms of Service resulting in account suspension</li>
                <li>Purchases made more than 30 days ago</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Refund Process</h2>
              <p className="text-muted-foreground">
                To request a refund:
              </p>
              <ol className="list-decimal list-inside text-muted-foreground space-y-2">
                <li>Contact support via Discord or email at refunds@hidebot.lol</li>
                <li>Provide your account email and transaction ID</li>
                <li>Explain the reason for the refund request</li>
                <li>Allow 3-5 business days for review</li>
                <li>If approved, refund will be processed to original payment method within 7-10 business days</li>
              </ol>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Partial Refunds</h2>
              <p className="text-muted-foreground">
                In some cases, we may offer partial refunds based on the number of unused prompts remaining in your account.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Donations</h2>
              <p className="text-muted-foreground">
                Donations made through the PayPal donate button are voluntary contributions and are non-refundable.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Chargebacks</h2>
              <p className="text-muted-foreground">
                Initiating a chargeback without first contacting support may result in immediate account suspension. Please contact us to resolve any issues.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Service Credits</h2>
              <p className="text-muted-foreground">
                In cases of service disruption, we may offer service credits (additional prompts) as an alternative to refunds.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Policy Changes</h2>
              <p className="text-muted-foreground">
                We reserve the right to modify this refund policy. Changes will be communicated via email to active users.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">Questions?</h2>
              <p className="text-muted-foreground">
                Have questions about refunds? Contact our support team via Discord or email at refunds@hidebot.lol
              </p>
            </section>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default Refund;
