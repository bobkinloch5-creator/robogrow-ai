import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Link } from "react-router-dom";
import Navbar from "@/components/Navbar";
import {
  Sparkles,
  Zap,
  Shield,
  Rocket,
  Bot,
  Code2,
  Wand2,
  MessageSquare,
  Gauge,
  Puzzle,
  PlayCircle,
} from "lucide-react";
import bloxsmithIcon from "@/assets/bloxsmith-icon.png";
import heroBg from "@/assets/roblox-hero-bg.jpg";
import tutorialVideo from "@/assets/plugin-tutorial.mp4.asset.json";


const features = [
  {
    icon: Bot,
    title: "AI Copilot in Studio",
    description:
      "Bloxsmith lives inside Roblox Studio, understands your project, and builds alongside you.",
  },
  {
    icon: Code2,
    title: "Generate Full Systems",
    description:
      "Inventories, shops, quests, combat, leaderboards and progression — generated and wired up for you.",
  },
  {
    icon: Wand2,
    title: "Fix & Optimize",
    description:
      "Explain, refactor and repair existing Lua scripts with one prompt while keeping full undo control.",
  },
  {
    icon: Shield,
    title: "Security & Safety",
    description:
      "Every change runs through ChangeHistoryService, so you approve and can undo anything instantly.",
  },
  {
    icon: Gauge,
    title: "Performance Analysis",
    description:
      "Real-time scanning surfaces bottlenecks, risky patterns and cleanup opportunities automatically.",
  },
  {
    icon: MessageSquare,
    title: "Natural Language",
    description:
      "Describe what you want — \"add a dash ability\", \"harder enemies\" — and watch it happen.",
  },
];

const steps = [
  {
    step: "01",
    title: "Install the plugin",
    description: "Add the Bloxsmith plugin to Roblox Studio in one click — no account required.",
  },
  {
    step: "02",
    title: "Open Bloxsmith",
    description: "Launch the plugin from your Studio toolbar and you're ready to go instantly.",
  },
  {
    step: "03",
    title: "Build with AI",
    description: "Prompt Bloxsmith to create, fix and improve your game live.",
  },
];

const Index = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      {/* Hero Section */}
      <section className="relative pt-32 pb-24 px-4 overflow-hidden">
        {/* Roblox-themed background */}
        <img
          src={heroBg}
          alt=""
          aria-hidden="true"
          width={1920}
          height={1280}
          className="pointer-events-none absolute inset-0 h-full w-full object-cover object-bottom"
        />
        {/* Readability + brand overlays */}
        <div className="pointer-events-none absolute inset-0 bg-background/40" />
        <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-background via-background/50 to-background" />
        <div className="pointer-events-none absolute inset-0 bg-grid opacity-30" />
        <div className="pointer-events-none absolute inset-0 bg-gradient-glow animate-pulse-glow" />


        <div className="container mx-auto relative z-10">
          <div className="max-w-4xl mx-auto text-center space-y-8 animate-slide-up">
            <div className="flex justify-center">
              <div className="relative">
                <div className="absolute inset-0 bg-gradient-glow blur-2xl animate-pulse-glow" />
                <img
                  src={bloxsmithIcon}
                  alt="Bloxsmith logo"
                  width={816}
                  height={816}
                  className="relative h-28 w-28 md:h-36 md:w-36 animate-float drop-shadow-[0_10px_40px_hsl(var(--primary)/0.5)]"
                />
              </div>
            </div>
            <div className="inline-flex items-center gap-2 rounded-full border border-border bg-card/60 px-4 py-1.5 text-sm text-muted-foreground backdrop-blur-sm">
              <Sparkles className="h-4 w-4 text-primary" />
              Meet Bloxsmith — your AI Roblox copilot
            </div>
            <h1 className="text-5xl md:text-7xl lg:text-8xl font-black tracking-tight leading-[1.05]">
              Build{" "}
              <span className="bg-gradient-primary bg-clip-text text-transparent">
                Advanced
              </span>{" "}
              Roblox Games with AI
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-2xl mx-auto">
              Turn your ideas into professional Roblox games instantly. Bloxsmith
              writes the code, builds the systems, and improves your game right
              inside Roblox Studio.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center pt-4">
              <a href="#tutorial">
                <Button
                  size="lg"
                  className="bg-gradient-primary shadow-glow text-lg px-8 h-14"
                >
                  <PlayCircle className="mr-2 h-5 w-5" />
                  Watch Install Tutorial
                </Button>
              </a>
              <Link to="/docs">
                <Button
                  size="lg"
                  variant="outline"
                  className="text-lg px-8 h-14"
                >
                  <Puzzle className="mr-2 h-5 w-5" />
                  Get the Plugin
                </Button>
              </Link>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-6 max-w-xl mx-auto pt-12">
              {[
                { value: "10x", label: "Faster builds" },
                { value: "50+", label: "Game systems" },
                { value: "100%", label: "Undoable changes" },
              ].map((stat) => (
                <div key={stat.label} className="text-center">
                  <div className="text-3xl md:text-4xl font-black bg-gradient-primary bg-clip-text text-transparent">
                    {stat.value}
                  </div>
                  <div className="text-sm text-muted-foreground mt-1">
                    {stat.label}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">
              Everything You Need to{" "}
              <span className="bg-gradient-primary bg-clip-text text-transparent">
                Create
              </span>
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              An advanced AI development assistant that helps you build, debug and
              ship faster — while you stay in full control.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((feature) => (
              <Card
                key={feature.title}
                className="bg-gradient-card p-6 border-border/50 hover:shadow-card transition-all hover:-translate-y-1"
              >
                <div className="w-12 h-12 rounded-xl bg-gradient-primary flex items-center justify-center mb-4 shadow-glow">
                  <feature.icon className="h-6 w-6 text-primary-foreground" />
                </div>
                <h3 className="text-xl font-bold mb-2">{feature.title}</h3>
                <p className="text-muted-foreground">{feature.description}</p>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">
              How It{" "}
              <span className="bg-gradient-primary bg-clip-text text-transparent">
                Works
              </span>
            </h2>
            <p className="text-xl text-muted-foreground">
              From idea to playable game in three steps
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {steps.map((item) => (
              <Card
                key={item.step}
                className="bg-gradient-card p-8 border-border/50 relative overflow-hidden"
              >
                <div className="text-7xl font-black bg-gradient-primary bg-clip-text text-transparent opacity-40 absolute top-2 right-4 drop-shadow-[0_0_20px_hsl(var(--primary)/0.5)]">
                  {item.step}
                </div>

                <div className="relative z-10">
                  <h3 className="text-xl font-bold mb-2">{item.title}</h3>
                  <p className="text-muted-foreground">{item.description}</p>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* Video Tutorial Section */}
      <section id="tutorial" className="py-20 px-4 scroll-mt-20">
        <div className="container mx-auto">
          <div className="text-center mb-12">
            <div className="inline-flex items-center gap-2 rounded-full border border-border bg-card/60 px-4 py-1.5 text-sm text-muted-foreground backdrop-blur-sm mb-4">
              <PlayCircle className="h-4 w-4 text-primary" />
              Step-by-step video guide
            </div>
            <h2 className="text-4xl md:text-5xl font-bold mb-4">
              How to{" "}
              <span className="bg-gradient-primary bg-clip-text text-transparent">
                Install
              </span>{" "}
              the Plugin
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Watch this quick tutorial to get Bloxsmith running inside Roblox
              Studio in minutes.
            </p>
          </div>

          <div className="max-w-4xl mx-auto">
            <Card className="bg-gradient-card border-border/50 p-2 md:p-3 shadow-elegant overflow-hidden">
              <div className="relative aspect-video rounded-xl overflow-hidden bg-background/60">
                <video
                  controls
                  playsInline
                  preload="metadata"
                  poster={heroBg}
                  className="h-full w-full object-cover"
                >
                  <source src="/plugin-tutorial.mp4" type="video/mp4" />
                  Your browser does not support the video tag.
                </video>
              </div>
            </Card>
            <p className="text-center text-sm text-muted-foreground mt-4">
              Need help? Join our{" "}
              <a
                href="https://discord.gg/gkYGrVBbca"
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:underline"
              >
                Discord community
              </a>{" "}
              for live support.
            </p>
          </div>
        </div>
      </section>


      {/* CTA Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <Card className="bg-gradient-hero p-12 text-center border-border/50 shadow-elegant relative overflow-hidden">
            <div className="absolute inset-0 bg-gradient-glow animate-pulse-glow" />
            <div className="relative z-10">
              <h2 className="text-4xl md:text-5xl font-bold mb-6">
                Ready to Build Your Dream Game?
              </h2>
              <p className="text-xl text-white/80 mb-8 max-w-2xl mx-auto">
                Join creators using Bloxsmith to build professional Roblox games
                faster than ever.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link to="/docs">
                  <Button
                    size="lg"
                    className="bg-background text-primary hover:bg-background/90 shadow-glow text-lg px-8 h-14"
                  >
                    <Rocket className="mr-2 h-5 w-5" />
                    Get the Plugin — It's Free
                  </Button>
                </Link>
              </div>
            </div>
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
                <Link
                  to="/docs"
                  className="block text-muted-foreground hover:text-foreground"
                >
                  Documentation
                </Link>
                <a
                  href="#tutorial"
                  className="block text-muted-foreground hover:text-foreground"
                >
                  Install Tutorial
                </a>
              </div>
            </div>
            <div>
              <h3 className="font-bold mb-4">Legal</h3>
              <div className="space-y-2">
                <Link
                  to="/terms"
                  className="block text-muted-foreground hover:text-foreground"
                >
                  Terms of Service
                </Link>
                <Link
                  to="/privacy"
                  className="block text-muted-foreground hover:text-foreground"
                >
                  Privacy Policy
                </Link>
              </div>

            </div>
            <div>
              <h3 className="font-bold mb-4">Support</h3>
              <div className="space-y-2">
                <Link
                  to="/faq"
                  className="block text-muted-foreground hover:text-foreground"
                >
                  FAQ
                </Link>
                <a
                  href="https://discord.gg/gkYGrVBbca"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block text-muted-foreground hover:text-foreground"
                >
                  Discord Community
                </a>
              </div>
            </div>
            <div>
              <h3 className="font-bold mb-4">Bloxsmith</h3>
              <p className="text-muted-foreground text-sm">
                AI-powered Roblox game builder. Create professional games with
                natural language.
              </p>
            </div>
          </div>
          <div className="mt-8 pt-8 border-t border-border text-center text-muted-foreground">
            <p>&copy; 2025 Bloxsmith. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Index;
