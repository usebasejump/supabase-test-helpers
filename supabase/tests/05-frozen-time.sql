--- function that specifically sets the search path so we can test how it handles overriden functions
CREATE OR REPLACE FUNCTION search_path_setting_function()
    RETURNS timestamp with time zone
AS $$
    SELECT now()
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_catalog;


BEGIN;
    CREATE EXTENSION supabase_test_helpers;
    
    select plan(12);

    -- freeze the time
    SELECT tests.freeze_time('2020-01-01 00:00:00');

    -- search_path now include test_overrides at the front
    select ok(
        (SELECT current_setting('search_path')::text LIKE 'test_overrides,%'),
        'search_path includes test_overrides at the front'
    );

    -- verify frozen time
     select is(
        (SELECT now()),
        '2020-01-01 00:00:00'::timestamp with time zone,
        'now() is frozen in time'
    );


    -- create a test table to verify that now() is overwritten on tables
    CREATE TABLE public.test_table (
        id int, 
        key text,
        created_at timestamp with time zone default now(),
        updated_at timestamp with time zone default now()
    );

    -- add a trigger to update updated_at when the row is updated
    CREATE OR REPLACE FUNCTION update_updated_at()
        RETURNS trigger
    AS $$
    BEGIN
        NEW.updated_at = now();
        RETURN NEW;
    END
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER update_updated_at
        BEFORE UPDATE ON test_table
        FOR EACH ROW
        EXECUTE PROCEDURE update_updated_at();

    -- insert a row and verify that the created_at and updated_at are frozen in time
    INSERT INTO test_table (id, key) VALUES (1, 'test');
    select is(
        (SELECT created_at FROM test_table WHERE id = 1),
        '2020-01-01 00:00:00'::timestamp with time zone,
        'created_at is frozen in time'
    );
    select is(
        (SELECT updated_at FROM test_table WHERE id = 1),
        '2020-01-01 00:00:00'::timestamp with time zone,
        'updated_at is frozen in time'
    );

    -- change frozen time to test updated_at timestamp
    SELECT tests.freeze_time('2021-01-01 00:00:00');

    -- update the row and verify that the updated_at is frozen in time
    UPDATE test_table SET key = 'test2' WHERE id = 1;

    select is(
        (SELECT updated_at FROM test_table WHERE id = 1),
        '2021-01-01 00:00:00'::timestamp with time zone,
        'updated_at is frozen in time'
    );

    -- verify supports many different inputs correctly
    SELECT tests.freeze_time('2020-02-02 00:00:00'::timestamp without time zone);
    select is(
        (SELECT now()),
        '2020-02-02 00:00:00'::timestamp with time zone,
        'Supports timestamp without time zone'
    );

    SELECT tests.freeze_time('2020-03-03'::date);
    select is(
        (SELECT now()),
        '2020-03-03 00:00:00'::timestamp with time zone,
        'Supports date'
    );

    SELECT tests.freeze_time(CURRENT_DATE);
    select is(
        (SELECT now()),
        CURRENT_DATE::timestamp with time zone,
        'Supports CURRENT_DATE'
    );

    SELECT tests.unfreeze_time();

    select is(
        (SELECT now()),
        (SELECT pg_catalog.now()),
        'unfreeze_time() restores now() to the original function'
    );


    ---- working with functions that have set their own search_path

    SELECT tests.freeze_time('2020-01-01 00:00:00');

    -- function still returns the non frozen time
    select is(
        (SELECT search_path_setting_function()),
        (SELECT pg_catalog.now()),
        'function still returns the non frozen time'
    );

    -- we can run an alter command to alter it specifically
    ALTER FUNCTION search_path_setting_function()
        SET search_path = test_overrides, public, pg_catalog;

    -- now it returns the frozen time
    select is(
        (SELECT search_path_setting_function()),
        '2020-01-01 00:00:00'::timestamp with time zone,
        'function returns the frozen time'
    );


    select tests.unfreeze_time();

    -- working with an authenticated user freezing time.

    select tests.create_supabase_user('test');
    select tests.authenticate_as('test');

    -- freeze time
    SELECT tests.freeze_time('2020-05-05 00:00:00');

    -- verify frozen time by creating a table row
    insert into test_table (id, key) values (2, 'test2');

    select is(
        (SELECT created_at FROM test_table WHERE id = 2),
        '2020-05-05 00:00:00'::timestamp with time zone,
        'created_at is frozen in time'
    );

    SELECT * FROM finish();
ROLLBACK;