--- secondary test to confirm that the search_path is restored after a rollback
BEGIN;
    CREATE EXTENSION supabase_test_helpers;
    
    select plan(2);

    -- freeze the time
    SELECT tests.freeze_time('2020-01-01 00:00:00');

    -- function still returns the non frozen time
    select is(
        (SELECT search_path_setting_function()),
        (SELECT pg_catalog.now()),
        'function still returns the non frozen time'
    );

    -- confirm test_overrides no longer in search path
    select ok(
        (SELECT current_setting('search_path') NOT LIKE 'test_overrides,%'),
        'test_overrides no longer in search path'
    );

    SELECT * FROM finish();
ROLLBACK;