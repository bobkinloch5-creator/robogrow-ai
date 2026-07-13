import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Slider } from "@/components/ui/slider";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { toast } from "@/hooks/use-toast";
import {
  Loader2, Trash2, ShieldCheck, UserPlus, LogOut, Globe, Lock, Gauge,
  BarChart3, RefreshCw, Save,
} from "lucide-react";

const FN_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/bloxsmith-ai`;
const ANON = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string;

type AllowedUser = {
  roblox_user_id: number;
  username: string | null;
  label: string | null;
  created_at: string;
};

type Settings = { access_mode: "public" | "allowlist"; daily_request_limit: number };

type UsageRow = {
  roblox_user_id: number;
  username: string | null;
  request_count: number;
  updated_at: string;
};

async function callAdmin(payload: Record<string, unknown>) {
  const res = await fetch(FN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: ANON,
      Authorization: `Bearer ${ANON}`,
    },
    body: JSON.stringify(payload),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.error || `Request failed (${res.status})`);
  return data;
}

const Admin = () => {
  const [adminKey, setAdminKey] = useState("");
  const [authed, setAuthed] = useState(false);
  const [users, setUsers] = useState<AllowedUser[]>([]);
  const [loading, setLoading] = useState(false);

  const [newUser, setNewUser] = useState("");
  const [newLabel, setNewLabel] = useState("");
  const [adding, setAdding] = useState(false);

  const [settings, setSettings] = useState<Settings>({ access_mode: "public", daily_request_limit: 100 });
  const [limitDraft, setLimitDraft] = useState(100);
  const [savingSettings, setSavingSettings] = useState(false);

  const [usage, setUsage] = useState<UsageRow[]>([]);
  const [usageTotals, setUsageTotals] = useState({ totalRequests: 0, uniqueUsers: 0, date: "" });
  const [usageLoading, setUsageLoading] = useState(false);

  const loadUsage = async (key: string) => {
    setUsageLoading(true);
    try {
      const data = await callAdmin({ mode: "admin_usage", adminKey: key });
      setUsage(data.usage || []);
      setUsageTotals({
        totalRequests: data.totalRequests || 0,
        uniqueUsers: data.uniqueUsers || 0,
        date: data.date || "",
      });
    } catch (e) {
      toast({ title: "Couldn't load usage", description: (e as Error).message, variant: "destructive" });
    } finally {
      setUsageLoading(false);
    }
  };

  const load = async (key: string) => {
    setLoading(true);
    try {
      const [list, settingsRes] = await Promise.all([
        callAdmin({ mode: "admin_list", adminKey: key }),
        callAdmin({ mode: "admin_get_settings", adminKey: key }),
      ]);
      setUsers(list.users || []);
      const s: Settings = settingsRes.settings || { access_mode: "public", daily_request_limit: 100 };
      setSettings(s);
      setLimitDraft(s.daily_request_limit);
      setAuthed(true);
      loadUsage(key);
    } catch (e) {
      toast({ title: "Access denied", description: (e as Error).message, variant: "destructive" });
      setAuthed(false);
    } finally {
      setLoading(false);
    }
  };

  const saveSettings = async (patch: Partial<{ accessMode: string; dailyRequestLimit: number }>) => {
    setSavingSettings(true);
    try {
      const data = await callAdmin({ mode: "admin_set_settings", adminKey, ...patch });
      const s: Settings = data.settings;
      setSettings(s);
      setLimitDraft(s.daily_request_limit);
      toast({ title: "Settings saved" });
    } catch (e) {
      toast({ title: "Couldn't save settings", description: (e as Error).message, variant: "destructive" });
    } finally {
      setSavingSettings(false);
    }
  };

  const handleAdd = async () => {
    const val = newUser.trim();
    if (!val) return;
    setAdding(true);
    try {
      const isId = /^\d+$/.test(val);
      await callAdmin({
        mode: "admin_add",
        adminKey,
        robloxUserId: isId ? Number(val) : undefined,
        username: isId ? undefined : val,
        label: newLabel.trim() || undefined,
      });
      toast({ title: "User added", description: `${val} can now use the plugin.` });
      setNewUser("");
      setNewLabel("");
      await load(adminKey);
    } catch (e) {
      toast({ title: "Couldn't add user", description: (e as Error).message, variant: "destructive" });
    } finally {
      setAdding(false);
    }
  };

  const handleRemove = async (id: number) => {
    try {
      await callAdmin({ mode: "admin_remove", adminKey, robloxUserId: id });
      setUsers((u) => u.filter((x) => x.roblox_user_id !== id));
      toast({ title: "User removed" });
    } catch (e) {
      toast({ title: "Couldn't remove user", description: (e as Error).message, variant: "destructive" });
    }
  };

  if (!authed) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background px-4">
        <Card className="w-full max-w-md p-8 space-y-6 border-border/60">
          <div className="flex items-center gap-3">
            <ShieldCheck className="h-7 w-7 text-primary" />
            <div>
              <h1 className="text-xl font-bold">Bloxsmith Owner Panel</h1>
              <p className="text-sm text-muted-foreground">Owner-only control center</p>
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="key">Admin password</Label>
            <Input
              id="key"
              type="password"
              value={adminKey}
              onChange={(e) => setAdminKey(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && load(adminKey)}
              placeholder="Enter your admin password"
              autoFocus
            />
          </div>
          <Button className="w-full" onClick={() => load(adminKey)} disabled={loading || !adminKey}>
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Unlock"}
          </Button>
        </Card>
      </div>
    );
  }

  const isPublic = settings.access_mode === "public";
  const limitChanged = limitDraft !== settings.daily_request_limit;

  return (
    <div className="min-h-screen bg-background px-4 py-10">
      <div className="mx-auto max-w-3xl space-y-8">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <ShieldCheck className="h-7 w-7 text-primary" />
            <div>
              <h1 className="text-2xl font-bold">Owner Panel</h1>
              <p className="text-sm text-muted-foreground">
                Control access, limits, and see live usage.
              </p>
            </div>
          </div>
          <Button variant="ghost" size="sm" onClick={() => { setAuthed(false); setAdminKey(""); }}>
            <LogOut className="h-4 w-4 mr-1" /> Lock
          </Button>
        </div>

        {/* Access & limits */}
        <Card className="p-6 space-y-6 border-border/60">
          <h2 className="font-semibold flex items-center gap-2"><Gauge className="h-4 w-4" /> Access & limits</h2>

          <div className="flex items-start justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                {isPublic ? <Globe className="h-4 w-4 text-primary" /> : <Lock className="h-4 w-4 text-primary" />}
                <span className="font-medium">{isPublic ? "Public" : "Allow-list only"}</span>
              </div>
              <p className="text-sm text-muted-foreground">
                {isPublic
                  ? "Anyone with the plugin can build. The daily limit still applies."
                  : "Only Roblox accounts in your allow-list below can build."}
              </p>
            </div>
            <Switch
              checked={!isPublic}
              disabled={savingSettings}
              onCheckedChange={(v) => saveSettings({ accessMode: v ? "allowlist" : "public" })}
            />
          </div>

          <Separator />

          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <Label>Daily build limit per user</Label>
              <Badge variant="secondary" className="text-sm">{limitDraft} / day</Badge>
            </div>
            <Slider
              value={[limitDraft]}
              min={5}
              max={2000}
              step={5}
              onValueChange={(v) => setLimitDraft(v[0])}
            />
            <div className="flex items-center justify-between">
              <p className="text-xs text-muted-foreground">Resets at midnight UTC. Applies to every Roblox account.</p>
              <Button
                size="sm"
                disabled={!limitChanged || savingSettings}
                onClick={() => saveSettings({ dailyRequestLimit: limitDraft })}
              >
                {savingSettings ? <Loader2 className="h-4 w-4 animate-spin" /> : <><Save className="h-4 w-4 mr-1" /> Save</>}
              </Button>
            </div>
          </div>
        </Card>

        {/* Usage dashboard */}
        <Card className="border-border/60 overflow-hidden">
          <div className="px-6 py-4 border-b border-border/60 flex items-center justify-between">
            <h2 className="font-semibold flex items-center gap-2"><BarChart3 className="h-4 w-4" /> Usage today</h2>
            <Button variant="ghost" size="sm" onClick={() => loadUsage(adminKey)} disabled={usageLoading}>
              {usageLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
            </Button>
          </div>
          <div className="grid grid-cols-2 divide-x divide-border/60 border-b border-border/60">
            <div className="px-6 py-4">
              <p className="text-2xl font-bold">{usageTotals.totalRequests}</p>
              <p className="text-xs text-muted-foreground">Builds today{usageTotals.date ? ` (${usageTotals.date} UTC)` : ""}</p>
            </div>
            <div className="px-6 py-4">
              <p className="text-2xl font-bold">{usageTotals.uniqueUsers}</p>
              <p className="text-xs text-muted-foreground">Active users</p>
            </div>
          </div>
          {usage.length === 0 ? (
            <p className="px-6 py-10 text-center text-sm text-muted-foreground">No builds yet today.</p>
          ) : (
            <ul className="divide-y divide-border/60">
              {usage.map((u) => {
                const atLimit = u.request_count >= settings.daily_request_limit;
                return (
                  <li key={u.roblox_user_id} className="px-6 py-3 flex items-center justify-between gap-4">
                    <div className="min-w-0">
                      <p className="font-medium truncate">
                        {u.username || "Roblox user"}{" "}
                        <span className="text-muted-foreground font-normal">#{u.roblox_user_id}</span>
                      </p>
                    </div>
                    <Badge variant={atLimit ? "destructive" : "secondary"}>
                      {u.request_count} / {settings.daily_request_limit}
                    </Badge>
                  </li>
                );
              })}
            </ul>
          )}
        </Card>

        {/* Allow-list */}
        <Card className="p-6 space-y-4 border-border/60">
          <h2 className="font-semibold flex items-center gap-2"><UserPlus className="h-4 w-4" /> Add a user to the allow-list</h2>
          {isPublic && (
            <p className="text-xs text-muted-foreground">
              Access is currently <span className="font-medium text-foreground">Public</span>, so the allow-list is not enforced. Switch to <span className="font-medium text-foreground">Allow-list only</span> above to restrict access to these users.
            </p>
          )}
          <div className="grid gap-3 sm:grid-cols-[1fr_1fr_auto] sm:items-end">
            <div className="space-y-1.5">
              <Label htmlFor="user">Roblox username or ID</Label>
              <Input id="user" value={newUser} onChange={(e) => setNewUser(e.target.value)}
                placeholder="e.g. builderman or 156" onKeyDown={(e) => e.key === "Enter" && handleAdd()} />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="label">Note (optional)</Label>
              <Input id="label" value={newLabel} onChange={(e) => setNewLabel(e.target.value)}
                placeholder="e.g. beta tester" onKeyDown={(e) => e.key === "Enter" && handleAdd()} />
            </div>
            <Button onClick={handleAdd} disabled={adding || !newUser.trim()}>
              {adding ? <Loader2 className="h-4 w-4 animate-spin" /> : "Add"}
            </Button>
          </div>
          <p className="text-xs text-muted-foreground">
            Tip: enter a username and Bloxsmith looks up the Roblox ID automatically.
          </p>
        </Card>

        <Card className="border-border/60 overflow-hidden">
          <div className="px-6 py-4 border-b border-border/60 flex items-center justify-between">
            <h2 className="font-semibold">Allow-list</h2>
            <span className="text-sm text-muted-foreground">{users.length} user{users.length === 1 ? "" : "s"}</span>
          </div>
          {users.length === 0 ? (
            <p className="px-6 py-10 text-center text-sm text-muted-foreground">
              No users yet. Add someone above to let them use the plugin in allow-list mode.
            </p>
          ) : (
            <ul className="divide-y divide-border/60">
              {users.map((u) => (
                <li key={u.roblox_user_id} className="px-6 py-4 flex items-center justify-between gap-4">
                  <div className="min-w-0">
                    <p className="font-medium truncate">
                      {u.username || `Roblox user`}{" "}
                      <span className="text-muted-foreground font-normal">#{u.roblox_user_id}</span>
                    </p>
                    {u.label && <p className="text-sm text-muted-foreground truncate">{u.label}</p>}
                  </div>
                  <Button variant="ghost" size="icon" onClick={() => handleRemove(u.roblox_user_id)}
                    className="text-destructive hover:text-destructive shrink-0">
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>
    </div>
  );
};

export default Admin;
