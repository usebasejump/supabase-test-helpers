BEGIN;
    --TODO: For now you have to specify the version due to a bug in pg_tle
    -- this should be changed to remove the version once the bug is fixed
    -- right now it always installs the FIRST version of the extension
    CREATE EXTENSION supabase_test_helpers version '0.0.4';
    
    select plan(4);
    -- create a table, which will have RLS disabled by default
    CREATE TABLE public.tb1 (id int, data text);
    -- test to make sure RLS check works
    select check_test(tests.rls_enabled('public'), false);
    select check_test(tests.rls_enabled('public', 'tb1'), false);

    -- enable RLS for the table
    ALTER TABLE public.tb1 ENABLE ROW LEVEL SECURITY;
    -- test to make sure RLS check works
    select check_test(tests.rls_enabled('public'), true);
    select check_test(tests.rls_enabled('public', 'tb1'), true);

    SELECT * FROM finish();
ROLLBACK;