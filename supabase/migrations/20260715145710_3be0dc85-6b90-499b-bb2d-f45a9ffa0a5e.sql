CREATE TABLE public.ai_jobs (
  job_id TEXT PRIMARY KEY,
  roblox_user_id BIGINT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  partial TEXT NOT NULL DEFAULT '',
  reply TEXT,
  actions JSONB,
  provider TEXT,
  mode TEXT,
  error TEXT,
  done BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT ALL ON public.ai_jobs TO service_role;
ALTER TABLE public.ai_jobs ENABLE ROW LEVEL SECURITY;
-- No policies: only service_role (edge function) accesses this table.
CREATE INDEX ai_jobs_updated_at_idx ON public.ai_jobs (updated_at);