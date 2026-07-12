import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import Navbar from "@/components/Navbar";
import { Sparkles, Zap, TrendingUp, MessageSquare } from "lucide-react";
import { User } from "@supabase/supabase-js";

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
              <h3 className="text-sm font-medium text-muted-foreground">Prompt Balance</h3>
              <Sparkles className="h-5 w-5 text-primary" />
            </div>
            <p className="text-3xl font-bold">50</p>
            <p className="text-xs text-muted-foreground mt-1">prompts remaining</p>
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
          <h2 className="text-2xl font-bold mb-4">Start Building with AI</h2>
          <p className="text-muted-foreground mb-6">
            Connect the Bloxsmith plugin in Roblox Studio to start creating games with AI
          </p>
          <div className="flex flex-col sm:flex-row gap-4">
            <a href="/Bloxsmith.lua" download="Bloxsmith.lua">
              <Button className="bg-background text-primary hover:bg-background/90 w-full">
                Download Plugin (.lua)
              </Button>
            </a>
            <a href="/docs">
              <Button variant="outline" className="w-full">
                View Documentation
              </Button>
            </a>
          </div>

        </Card>

        {/* Purchase Prompts */}
        <Card className="bg-gradient-card p-8 border-border/50">
          <h2 className="text-2xl font-bold mb-4">Get More Prompts</h2>
          <p className="text-muted-foreground mb-6">
            Purchase additional prompts to build more advanced games
          </p>
          
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-background/50 rounded-lg">
              <div>
                <h3 className="font-bold">100 Prompts</h3>
                <p className="text-sm text-muted-foreground">Perfect for small projects</p>
              </div>
              <Button className="bg-gradient-primary">$9.99</Button>
            </div>
            
            <div className="flex items-center justify-between p-4 bg-background/50 rounded-lg">
              <div>
                <h3 className="font-bold">500 Prompts</h3>
                <p className="text-sm text-muted-foreground">Most popular choice</p>
              </div>
              <Button className="bg-gradient-primary">$39.99</Button>
            </div>
            
            <div className="flex items-center justify-between p-4 bg-background/50 rounded-lg">
              <div>
                <h3 className="font-bold">1000 Prompts</h3>
                <p className="text-sm text-muted-foreground">Best value for teams</p>
              </div>
              <Button className="bg-gradient-primary">$69.99</Button>
            </div>
          </div>

          <div className="mt-6 p-4 bg-background/30 rounded-lg border border-border/50">
            <p className="text-sm text-center">
              <span className="font-semibold">Support the Project:</span> Donate via PayPal to help keep Bloxsmith free
            </p>
            <div className="flex justify-center mt-3">
              <Button variant="outline" size="sm">
                Donate with PayPal
              </Button>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default Dashboard;
