CREATE TABLE public.app_settings (
  id integer PRIMARY KEY DEFAULT 1,
  access_mode text NOT NULL DEFAULT 'public',
  daily_request_limit integer NOT NULL DEFAULT 100,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT app_settings_singleton CHECK (id = 1),
  CONSTRAINT app_settings_access_mode_valid CHECK (access_mode IN ('public','allowlist')),
  CONSTRAINT app_settings_limit_range CHECK (daily_request_limit BETWEEN 1 AND 100000)
);

GRANT ALL ON public.app_settings TO service_role;

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
-- No policies: only the edge function (service role) may read/write settings.

INSERT INTO public.app_settings (id, access_mode, daily_request_limit)
VALUES (1, 'public', 100)
ON CONFLICT (id) DO NOTHING;