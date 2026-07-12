import { useState, useRef, useEffect } from "react";
import ReactMarkdown from "react-markdown";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { MessageCircle, X, Send, Bot } from "lucide-react";
import { cn } from "@/lib/utils";
import bloxsmithIcon from "@/assets/bloxsmith-icon.png";

type Msg = { role: "user" | "assistant"; content: string };

const DISCORD_URL = "https://discord.gg/gkYGrVBbca";

const SUGGESTIONS = [
  "How do I install the plugin?",
  "How do I get started?",
  "What can Bloxsmith build?",
];

const WELCOME: Msg = {
  role: "assistant",
  content:
    "👋 Hi! I'm the Bloxsmith AI assistant. I can help you **install the plugin**, get started, and answer questions. What would you like to know?",
};

const SupportChat = () => {
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState<Msg[]>([WELCOME]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [messages, loading]);

  useEffect(() => {
    if (open) inputRef.current?.focus();
  }, [open]);

  const send = async (text: string) => {
    const trimmed = text.trim();
    if (!trimmed || loading) return;

    const history: Msg[] = [...messages.filter((m) => m !== WELCOME), { role: "user", content: trimmed }];
    setMessages((prev) => [...prev, { role: "user", content: trimmed }]);
    setInput("");
    setLoading(true);

    try {
      const { data, error } = await supabase.functions.invoke("bloxsmith-ai", {
        body: { mode: "support", messages: history },
      });
      if (error) throw error;
      const reply = (data as { reply?: string; error?: string })?.reply;
      const errMsg = (data as { error?: string })?.error;
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content:
            reply ||
            errMsg ||
            "Sorry, I couldn't reach the assistant right now. Please try again, or join our Discord for help.",
        },
      ]);
    } catch {
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content:
            "Sorry, something went wrong. Please try again in a moment, or join our [Discord](" +
            DISCORD_URL +
            ") for direct support.",
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      {/* Launcher */}
      {!open && (
        <button
          onClick={() => setOpen(true)}
          aria-label="Open Bloxsmith support chat"
          className="fixed bottom-5 right-5 z-50 flex items-center gap-2 rounded-full bg-gradient-primary pl-3 pr-4 py-3 shadow-glow transition-transform hover:scale-105"
        >
          <MessageCircle className="h-5 w-5 text-primary-foreground" />
          <span className="text-sm font-semibold text-primary-foreground">Need help?</span>
        </button>
      )}

      {/* Panel */}
      {open && (
        <div className="fixed bottom-5 right-5 z-50 flex h-[560px] max-h-[80vh] w-[380px] max-w-[calc(100vw-2.5rem)] flex-col overflow-hidden rounded-2xl border border-border/60 bg-card shadow-elegant animate-in slide-in-from-bottom-4">
          {/* Header */}
          <div className="flex items-center justify-between gap-3 border-b border-border/60 bg-gradient-primary px-4 py-3">
            <div className="flex items-center gap-3">
              <img src={bloxsmithIcon} alt="Bloxsmith" className="h-8 w-8 rounded-lg" />
              <div>
                <p className="text-sm font-bold leading-tight text-primary-foreground">Bloxsmith Assistant</p>
                <p className="text-xs leading-tight text-primary-foreground/80">Powered by AI · Online</p>
              </div>
            </div>
            <button
              onClick={() => setOpen(false)}
              aria-label="Close chat"
              className="rounded-lg p-1 text-primary-foreground/90 transition-colors hover:bg-white/10"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          {/* Messages */}
          <div ref={scrollRef} className="flex-1 space-y-4 overflow-y-auto p-4">
            {messages.map((m, i) => (
              <div key={i} className={cn("flex gap-2", m.role === "user" ? "justify-end" : "justify-start")}>
                {m.role === "assistant" && (
                  <div className="mt-1 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary/15 text-primary">
                    <Bot className="h-4 w-4" />
                  </div>
                )}
                <div
                  className={cn(
                    "max-w-[80%] rounded-2xl px-3 py-2 text-sm",
                    m.role === "user"
                      ? "bg-primary text-primary-foreground rounded-br-sm"
                      : "bg-muted text-foreground rounded-bl-sm",
                  )}
                >
                  <div className="prose prose-sm prose-invert max-w-none break-words [&_a]:text-primary [&_p]:my-1 [&_ol]:my-1 [&_ul]:my-1 [&_li]:my-0.5">
                    <ReactMarkdown>{m.content}</ReactMarkdown>
                  </div>
                </div>
              </div>
            ))}

            {loading && (
              <div className="flex gap-2">
                <div className="mt-1 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary/15 text-primary">
                  <Bot className="h-4 w-4" />
                </div>
                <div className="flex items-center gap-1 rounded-2xl rounded-bl-sm bg-muted px-4 py-3">
                  <span className="h-2 w-2 animate-bounce rounded-full bg-muted-foreground/60 [animation-delay:-0.3s]" />
                  <span className="h-2 w-2 animate-bounce rounded-full bg-muted-foreground/60 [animation-delay:-0.15s]" />
                  <span className="h-2 w-2 animate-bounce rounded-full bg-muted-foreground/60" />
                </div>
              </div>
            )}

            {messages.length <= 1 && !loading && (
              <div className="flex flex-wrap gap-2 pt-1">
                {SUGGESTIONS.map((s) => (
                  <button
                    key={s}
                    onClick={() => send(s)}
                    className="rounded-full border border-border/60 bg-background/50 px-3 py-1.5 text-xs text-foreground/80 transition-colors hover:border-primary hover:text-foreground"
                  >
                    {s}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Composer */}
          <div className="border-t border-border/60 p-3">
            <form
              onSubmit={(e) => {
                e.preventDefault();
                send(input);
              }}
              className="flex items-center gap-2"
            >
              <Input
                ref={inputRef}
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Ask about installing Bloxsmith…"
                className="bg-background/60"
                disabled={loading}
              />
              <Button type="submit" size="icon" disabled={loading || !input.trim()} className="bg-gradient-primary shrink-0">
                <Send className="h-4 w-4" />
              </Button>
            </form>
            <p className="mt-2 text-center text-[11px] text-muted-foreground">
              Need a human?{" "}
              <a href={DISCORD_URL} target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">
                Join our Discord
              </a>
            </p>
          </div>
        </div>
      )}
    </>
  );
};

export default SupportChat;
