-- anon, authenticated, and service_role should have access to test_overrides schema
GRANT USAGE ON SCHEMA test_overrides TO anon, authenticated, service_role;
-- Don't allow public to execute any functions in the test_overrides schema
ALTER DEFAULT PRIVILEGES IN SCHEMA test_overrides REVOKE EXECUTE ON FUNCTIONS FROM public;
-- Grant execute to anon, authenticated, and service_role for testing purposes
ALTER DEFAULT PRIVILEGES IN SCHEMA test_overrides GRANT EXECUTE ON FUNCTIONS TO anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION test_overrides.now() TO anon, authenticated, service_role;