REVOKE EXECUTE ON FUNCTION public.check_and_increment_roblox_usage(bigint, integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.check_and_increment_roblox_usage(bigint, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.check_and_increment_roblox_usage(bigint, integer) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.check_and_increment_roblox_usage(bigint, integer) TO service_role;