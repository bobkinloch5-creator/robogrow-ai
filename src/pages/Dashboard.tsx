import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import Navbar from "@/components/Navbar";
import { Sparkles, Zap, TrendingUp, MessageSquare } from "lucide-react";
import { User } from "@supabase/supabase-js";

const PLUGIN_VERSION = "3.18.1";
const pluginDownloadUrl = `/Bloxsmith.lua?v=${PLUGIN_VERSION}`;

const Dashboard = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    const checkAuth = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      
      if (!session) {
        navigate("/auth");
        return;
      }

      setUser(session.user);
      setLoading(false);
    };

    checkAuth();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT') {
        navigate("/auth");
      }
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, [navigate]);

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    toast({
      title: "Signed out",
      description: "You have been successfully signed out.",
    });
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="animate-pulse text-xl">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      
      <div className="container mx-auto px-4 pt-24 pb-12">
        <div className="flex justify-between items-start mb-8">
          <div>
            <h1 className="text-4xl font-bold mb-2">
              Welcome Back! <span className="bg-gradient-primary bg-clip-text text-transparent">Builder</span>
            </h1>
            <p className="text-muted-foreground">
              {user?.email}
            </p>
          </div>
          <Button variant="outline" onClick={handleSignOut}>
            Sign Out
          </Button>
        </div>

        {/* Stats Grid */}
        <div className="grid md:grid-cols-4 gap-6 mb-8">
          <Card className="bg-gradient-card p-6 border-border/50">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-sm font-medium text-muted-foreground">Your Plan</h3>
              <Sparkles className="h-5 w-5 text-primary" />
            </div>
            <p className="text-3xl font-bold bg-gradient-primary bg-clip-text text-transparent">Free</p>
            <p className="text-xs text-muted-foreground mt-1">unlimited prompts</p>
          </Card>


          <Card className="bg-gradient-card p-6 border-border/50">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-sm font-medium text-muted-foreground">Games Created</h3>
              <Zap className="h-5 w-5 text-secondary" />
            </div>
            <p className="text-3xl font-bold">0</p>
            <p className="text-xs text-muted-foreground mt-1">total projects</p>
          </Card>

          <Card className="bg-gradient-card p-6 border-border/50">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-sm font-medium text-muted-foreground">This Week</h3>
              <TrendingUp className="h-5 w-5 text-accent" />
            </div>
            <p className="text-3xl font-bold">0</p>
            <p className="text-xs text-muted-foreground mt-1">prompts used</p>
          </Card>

          <Card className="bg-gradient-card p-6 border-border/50">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-sm font-medium text-muted-foreground">Modifications</h3>
              <MessageSquare className="h-5 w-5 text-primary" />
            </div>
            <p className="text-3xl font-bold">0</p>
            <p className="text-xs text-muted-foreground mt-1">total edits</p>
          </Card>
        </div>

        {/* AI Builder Card */}
        <Card className="bg-gradient-hero p-8 border-border/50 shadow-elegant mb-8">
          <div className="flex items-center gap-2 mb-2">
            <h2 className="text-2xl font-bold">Start Building with AI</h2>
            <span className="rounded-full bg-primary/15 text-primary px-2 py-0.5 font-mono text-xs">Plugin v{PLUGIN_VERSION}</span>
          </div>
          <p className="text-muted-foreground mb-6">
            Connect the Bloxsmith plugin in Roblox Studio to start creating games with AI
          </p>
          <div className="flex flex-col sm:flex-row gap-4">
            <a href={pluginDownloadUrl} download="Bloxsmith.lua">
              <Button className="bg-background text-primary hover:bg-background/90 w-full">
                Download Plugin (.lua) · v{PLUGIN_VERSION}
              </Button>
            </a>
            <a href="/docs">
              <Button variant="outline" className="w-full">
                View Documentation
              </Button>
            </a>
          </div>

        </Card>

        {/* 100% Free */}
        <Card className="bg-gradient-card p-8 border-border/50 text-center">
          <h2 className="text-2xl font-bold mb-2">Bloxsmith is 100% Free</h2>
          <p className="text-muted-foreground mb-6">
            No payments, no subscriptions, no hidden costs — build as much as you want, forever.
          </p>
          <div className="flex justify-center">
            <a href="https://discord.gg/gkYGrVBbca" target="_blank" rel="noopener noreferrer">
              <Button className="bg-gradient-primary shadow-glow">
                Join our Discord Community
              </Button>
            </a>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default Dashboard;

