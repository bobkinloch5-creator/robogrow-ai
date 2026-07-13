CREATE TABLE public.allowed_roblox_users (
  roblox_user_id BIGINT PRIMARY KEY,
  username TEXT,
  label TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Only the secure edge function (service role) reads/writes this list.
GRANT ALL ON public.allowed_roblox_users TO service_role;

-- Lock the table down: RLS enabled with no policies means no anon/authenticated
-- Data API access. The edge function uses the service role, which bypasses RLS.
ALTER TABLE public.allowed_roblox_users ENABLE ROW LEVEL SECURITY;