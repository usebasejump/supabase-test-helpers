-- Enable pgTAP if it's not already enabled
create extension if not exists pgtap with schema extensions;

-- We want to store all of this in the tests schema to keep it
-- separate from any application data
CREATE SCHEMA IF NOT EXISTS tests;

-- anon and authenticated should have access to tests schema
GRANT USAGE ON SCHEMA tests TO anon, authenticated;
-- Don't allow public to execute any functions in the tests schema
ALTER DEFAULT PRIVILEGES IN SCHEMA tests REVOKE EXECUTE ON FUNCTIONS FROM public;
-- Grant execute to anon and authenticated for testing purposes
ALTER DEFAULT PRIVILEGES IN SCHEMA tests GRANT EXECUTE ON FUNCTIONS TO anon, authenticated;

/**
    * ### tests.create_supabase_user(identifier text, email text, phone text)
    *
    * Creates a new user in the `auth.users` table.
    * You can recall a user's info by using `tests.get_supabase_user(identifier text)`.
    *
    * Parameters:
    * - `identifier` - A unique identifier for the user. We recommend you keep it memorable like "test_owner" or "test_member"
    * - `email` - (Optional) The email address of the user
    * - `phone` - (Optional) The phone number of the user
    *
    * Returns:
    * - `user_id` - The UUID of the user in the `auth.users` table
    *
    * Example:
    * ```sql
    *   SELECT tests.create_supabase_user('test_owner');
    *   SELECT tests.create_supabase_user('test_member', 'member@test.com', '555-555-5555');
    * ```
 */
CREATE OR REPLACE FUNCTION tests.create_supabase_user(identifier text, email text default null, phone text default null)
RETURNS uuid
    SECURITY DEFINER
    SET search_path = tests, auth, public, pg_temp
AS $$
DECLARE
    user_id uuid;
BEGIN

    -- create the user
    user_id := extensions.uuid_generate_v4();
    INSERT INTO auth.users (id, email, phone, raw_user_meta_data)
    VALUES (user_id, coalesce(email, concat(user_id, '@test.com')), phone, json_build_object('test_identifier', identifier))
    RETURNING id INTO user_id;

    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

/**
    * ### tests.get_supabase_user(identifier text)
    *
    * Returns the user info for a user created with `tests.create_supabase_user`.
    *
    * Parameters:
    * - `identifier` - The unique identifier for the user
    *
    * Returns:
    * - `user_id` - The UUID of the user in the `auth.users` table
    *
    * Example:
    * ```sql
    *   SELECT posts where posts.user_id = tests.get_supabase_user('test_owner') -> 'id';
    * ```
 */
CREATE OR REPLACE FUNCTION tests.get_supabase_user(identifier text)
RETURNS uuid
SECURITY DEFINER
SET search_path = tests, auth, public, pg_temp
AS $$
    DECLARE
        supabase_user uuid;
    BEGIN
        SELECT id into supabase_user FROM auth.users WHERE raw_user_meta_data ->> 'test_identifier' = identifier limit 1;
        if supabase_user is null then
            RAISE EXCEPTION 'User with identifier % not found', identifier;
        end if;
        RETURN supabase_user;
    END;
$$ LANGUAGE plpgsql;

/**
* ### tests.rls_enabled(testing_schema text)
* pgTAP function to check if RLS is enabled on all tables in a provided schema
*
* Parameters:
* - schema_name text - The name of the schema to check
*
* Example:
* ```sql
*   BEGIN;
*       select plan(1);
*       select tests.rls_enabled('public');
*       SELECT * FROM finish();
*   ROLLBACK;
* ```
*/
CREATE OR REPLACE FUNCTION tests.rls_enabled (testing_schema text)
RETURNS text AS $$
    select is(
        (select
           	count(pc.relname)::integer
           from pg_class pc
           join pg_namespace pn on pn.oid = pc.relnamespace and pn.nspname = rls_enabled.testing_schema
           join pg_type pt on pt.oid = pc.reltype
           where relrowsecurity = FALSE)
        ,
        0,
        'All tables in the' || testing_schema || ' schema should have row level security enabled');
$$ LANGUAGE sql;

/**
* ### tests.rls_enabled(testing_schema text, testing_table text)
* pgTAP function to check if RLS is enabled on a specific table
*
* Parameters:
* - schema_name text - The name of the schema to check
* - testing_table text - The name of the table to check
*
* Example:
* ```sql
*    BEGIN;
*        select plan(1);
*        select tests.rls_enabled('public', 'accounts');
*        SELECT * FROM finish();
*    ROLLBACK;
* ```
*/
CREATE OR REPLACE FUNCTION tests.rls_enabled (testing_schema text, testing_table text)
RETURNS TEXT AS $$
    select is(
        (select
           	count(*)::integer
           from pg_class pc
           join pg_namespace pn on pn.oid = pc.relnamespace and pn.nspname = rls_enabled.testing_schema and pc.relname = rls_enabled.testing_table
           join pg_type pt on pt.oid = pc.reltype
           where relrowsecurity = TRUE),
        1,
        testing_table || 'table in the' || testing_schema || ' schema should have row level security enabled'
    );
$$ LANGUAGE sql;