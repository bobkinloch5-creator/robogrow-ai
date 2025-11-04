import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Link } from "react-router-dom";
import Navbar from "@/components/Navbar";
import { Sparkles, Zap, Shield, Rocket } from "lucide-react";

const Index = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      
      {/* Hero Section */}
      <section className="relative pt-32 pb-20 px-4 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-hero opacity-50" />
        <div className="absolute inset-0 bg-gradient-glow animate-pulse-glow" />
        
        <div className="container mx-auto relative z-10">
          <div className="max-w-4xl mx-auto text-center space-y-8 animate-slide-up">
            <h1 className="text-6xl md:text-8xl font-black tracking-tight">
              Build <span className="bg-gradient-primary bg-clip-text text-transparent">Advanced</span> Roblox Games with AI
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-2xl mx-auto">
              Turn your ideas into professional Roblox games instantly. Powered by Amazon Bedrock AI and automated Studio integration.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center pt-4">
              <Link to="/auth?mode=signup">
                <Button size="lg" className="bg-gradient-primary shadow-glow text-lg px-8 h-14">
                  <Sparkles className="mr-2 h-5 w-5" />
                  Start Building Free
                </Button>
              </Link>
              <Link to="/docs">
                <Button size="lg" variant="outline" className="text-lg px-8 h-14">
                  View Documentation
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">
              Everything You Need to <span className="bg-gradient-primary bg-clip-text text-transparent">Create</span>
            </h2>
            <p className="text-xl text-muted-foreground">
              Advanced AI-powered tools for professional game development
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            <Card className="bg-gradient-card p-6 border-border/50 hover:shadow-card transition-all hover:-translate-y-1">
              <div className="w-12 h-12 rounded-xl bg-gradient-primary flex items-center justify-center mb-4">
                <Zap className="h-6 w-6" />
              </div>
              <h3 className="text-xl font-bold mb-2">AI Game Builder</h3>
              <p className="text-muted-foreground">
                Describe your game and watch AI create it automatically in Roblox Studio
              </p>
            </Card>

            <Card className="bg-gradient-card p-6 border-border/50 hover:shadow-card transition-all hover:-translate-y-1">
              <div className="w-12 h-12 rounded-xl bg-gradient-primary flex items-center justify-center mb-4">
                <Rocket className="h-6 w-6" />
              </div>
              <h3 className="text-xl font-bold mb-2">Instant Modifications</h3>
              <p className="text-muted-foreground">
                Make changes on the fly - "add shop system", "improve UI", "harder enemies"
              </p>
            </Card>

            <Card className="bg-gradient-card p-6 border-border/50 hover:shadow-card transition-all hover:-translate-y-1">
              <div className="w-12 h-12 rounded-xl bg-gradient-primary flex items-center justify-center mb-4">
                <Shield className="h-6 w-6" />
              </div>
              <h3 className="text-xl font-bold mb-2">Secure Integration</h3>
              <p className="text-muted-foreground">
                Safe authentication and automatic synchronization with Roblox Studio
              </p>
            </Card>

            <Card className="bg-gradient-card p-6 border-border/50 hover:shadow-card transition-all hover:-translate-y-1">
              <div className="w-12 h-12 rounded-xl bg-gradient-primary flex items-center justify-center mb-4">
                <Sparkles className="h-6 w-6" />
              </div>
              <h3 className="text-xl font-bold mb-2">Genre Support</h3>
              <p className="text-muted-foreground">
                FPS, RPG, simulation, sandbox - AI understands and builds any game type
              </p>
            </Card>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <Card className="bg-gradient-hero p-12 text-center border-border/50 shadow-elegant">
            <h2 className="text-4xl md:text-5xl font-bold mb-6">
              Ready to Build Your Dream Game?
            </h2>
            <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
              Join thousands of developers using Hide Bot to create professional Roblox games
            </p>
            <Link to="/auth?mode=signup">
              <Button size="lg" className="bg-background text-primary hover:bg-background/90 shadow-glow text-lg px-8 h-14">
                Get Started Now - It's Free
              </Button>
            </Link>
          </Card>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border py-12 px-4">
        <div className="container mx-auto">
          <div className="grid md:grid-cols-4 gap-8">
            <div>
              <h3 className="font-bold mb-4">Product</h3>
              <div className="space-y-2">
                <Link to="/docs" className="block text-muted-foreground hover:text-foreground">Documentation</Link>
                <Link to="/dashboard" className="block text-muted-foreground hover:text-foreground">Dashboard</Link>
              </div>
            </div>
            <div>
              <h3 className="font-bold mb-4">Legal</h3>
              <div className="space-y-2">
                <Link to="/terms" className="block text-muted-foreground hover:text-foreground">Terms of Service</Link>
                <Link to="/privacy" className="block text-muted-foreground hover:text-foreground">Privacy Policy</Link>
                <Link to="/refund" className="block text-muted-foreground hover:text-foreground">Refund Policy</Link>
              </div>
            </div>
            <div>
              <h3 className="font-bold mb-4">Support</h3>
              <div className="space-y-2">
                <Link to="/faq" className="block text-muted-foreground hover:text-foreground">FAQ</Link>
                <a href="https://discord.gg/hidebot" target="_blank" rel="noopener noreferrer" className="block text-muted-foreground hover:text-foreground">Discord Community</a>
              </div>
            </div>
            <div>
              <h3 className="font-bold mb-4">Hide Bot</h3>
              <p className="text-muted-foreground text-sm">
                AI-powered Roblox game builder. Create professional games with natural language.
              </p>
            </div>
          </div>
          <div className="mt-8 pt-8 border-t border-border text-center text-muted-foreground">
            <p>&copy; 2025 Hide Bot. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Index;
