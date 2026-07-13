import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card } from "@/components/ui/card";
import { toast } from "@/hooks/use-toast";
import { Loader2, Trash2, ShieldCheck, UserPlus, LogOut } from "lucide-react";

const FN_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/bloxsmith-ai`;
const ANON = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string;

type AllowedUser = {
  roblox_user_id: number;
  username: string | null;
  label: string | null;
  created_at: string;
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

  const load = async (key: string) => {
    setLoading(true);
    try {
      const data = await callAdmin({ mode: "admin_list", adminKey: key });
      setUsers(data.users || []);
      setAuthed(true);
    } catch (e) {
      toast({ title: "Access denied", description: (e as Error).message, variant: "destructive" });
      setAuthed(false);
    } finally {
      setLoading(false);
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
              <h1 className="text-xl font-bold">Bloxsmith Access</h1>
              <p className="text-sm text-muted-foreground">Owner-only allow-list manager</p>
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

  return (
    <div className="min-h-screen bg-background px-4 py-10">
      <div className="mx-auto max-w-3xl space-y-8">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <ShieldCheck className="h-7 w-7 text-primary" />
            <div>
              <h1 className="text-2xl font-bold">Allowed Roblox Users</h1>
              <p className="text-sm text-muted-foreground">
                Only these Roblox accounts can use the Bloxsmith plugin.
              </p>
            </div>
          </div>
          <Button variant="ghost" size="sm" onClick={() => { setAuthed(false); setAdminKey(""); }}>
            <LogOut className="h-4 w-4 mr-1" /> Lock
          </Button>
        </div>

        <Card className="p-6 space-y-4 border-border/60">
          <h2 className="font-semibold flex items-center gap-2"><UserPlus className="h-4 w-4" /> Add a user</h2>
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
              No users yet. Add someone above to let them use the plugin.
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
