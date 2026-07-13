-- Per-Roblox-user daily usage counter for ad-hoc rate limiting.
CREATE TABLE public.roblox_usage_daily (
  roblox_user_id bigint NOT NULL,
  usage_date date NOT NULL DEFAULT current_date,
  request_count integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (roblox_user_id, usage_date)
);

GRANT ALL ON public.roblox_usage_daily TO service_role;

ALTER TABLE public.roblox_usage_daily ENABLE ROW LEVEL SECURITY;
-- No policies: only the edge function (service role) may read/write this table.

-- Atomically increment today's counter for a Roblox user and report whether
-- they are still within their daily limit. Returns TRUE when allowed.
CREATE OR REPLACE FUNCTION public.check_and_increment_roblox_usage(
  _roblox_user_id bigint,
  _daily_limit integer
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_count integer;
BEGIN
  IF _roblox_user_id IS NULL OR _roblox_user_id <= 0 THEN
    RETURN true; -- can't identify user; don't block
  END IF;

  INSERT INTO public.roblox_usage_daily (roblox_user_id, usage_date, request_count)
  VALUES (_roblox_user_id, current_date, 1)
  ON CONFLICT (roblox_user_id, usage_date)
  DO UPDATE SET request_count = public.roblox_usage_daily.request_count + 1,
                updated_at = now()
  RETURNING request_count INTO current_count;

  RETURN current_count <= _daily_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_and_increment_roblox_usage(bigint, integer) TO service_role;