import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import hidebotLogo from "@/assets/hidebot-logo.png";

const Navbar = () => {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-card/80 backdrop-blur-lg border-b border-border">
      <div className="container mx-auto px-4 h-16 flex items-center justify-between">
        <Link to="/" className="flex items-center gap-3 group">
          <img src={hidebotLogo} alt="Hide Bot" className="h-8 w-auto transition-transform group-hover:scale-105" />
        </Link>
        
        <div className="hidden md:flex items-center gap-6">
          <Link to="/dashboard" className="text-foreground/80 hover:text-foreground transition-colors">
            Dashboard
          </Link>
          <Link to="/docs" className="text-foreground/80 hover:text-foreground transition-colors">
            Documentation
          </Link>
          <a href="https://discord.gg/hidebot" target="_blank" rel="noopener noreferrer" className="text-foreground/80 hover:text-foreground transition-colors">
            Discord
          </a>
        </div>

        <div className="flex items-center gap-3">
          <Link to="/auth">
            <Button variant="outline" size="sm">
              Sign In
            </Button>
          </Link>
          <Link to="/auth?mode=signup">
            <Button size="sm" className="bg-gradient-primary">
              Get Started
            </Button>
          </Link>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
