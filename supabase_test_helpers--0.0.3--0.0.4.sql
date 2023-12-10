--- Create a specific schema for override functions so we don't have to worry about
--- anything else be adding to the tests schema
CREATE SCHEMA IF NOT EXISTS test_overrides;

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
    * - `metadata` - (Optional) Additional metadata to be added to the user
    *
    * Returns:
    * - `user_id` - The UUID of the user in the `auth.users` table
    *
    * Example:
    * ```sql
    *   SELECT tests.create_supabase_user('test_owner');
    *   SELECT tests.create_supabase_user('test_member', 'member@test.com', '555-555-5555');
    *   SELECT tests.create_supabase_user('test_member', 'member@test.com', '555-555-5555', '{"key": "value"}'::jsonb);
    * ```
 */
CREATE OR REPLACE FUNCTION tests.create_supabase_user(identifier text, email text default null, phone text default null, metadata jsonb default null)
RETURNS uuid
    SECURITY DEFINER
    SET search_path = auth, pg_temp
AS $$
DECLARE
    user_id uuid;
BEGIN

    -- create the user
    user_id := extensions.uuid_generate_v4();
    INSERT INTO auth.users (id, email, phone, raw_user_meta_data, raw_app_meta_data, created_at, updated_at)
    VALUES (user_id, coalesce(email, concat(user_id, '@test.com')), phone, jsonb_build_object('test_identifier', identifier) || coalesce(metadata, '{}'::jsonb), '{}'::jsonb, now(), now())
    RETURNING id INTO user_id;

    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

--
--  Generated now() function used to replace pg_catalog.now() for the purpose
--  of freezing time in tests. This should not be used directly.
--
CREATE OR REPLACE FUNCTION test_overrides.now()
    RETURNS timestamp with time zone
AS $$
BEGIN


    -- check if a frozen time is set
    IF nullif(current_setting('tests.frozen_time'), '') IS NOT NULL THEN
        RETURN current_setting('tests.frozen_time')::timestamptz;
    END IF;

    RETURN pg_catalog.now();
END
$$ LANGUAGE plpgsql;


/**
    * ### tests.freeze_time(frozen_time timestamp with time zone)
    *
    * Overwrites the current time from now() to the provided time.
    *
    * Parameters:
    * - `frozen_time` - The time to freeze to. Supports timestamp with time zone, without time zone, date or any other value that can be coerced into a timestamp with time zone.
    *
    * Returns:
    * - void
    *
    * Example:
    * ```sql
    *   SELECT tests.freeze_time('2020-01-01 00:00:00');
    * ```
 */

CREATE OR REPLACE FUNCTION tests.freeze_time(frozen_time timestamp with time zone)
    RETURNS void
AS $$
BEGIN

    -- Add test_overrides to search path if needed
    IF current_setting('search_path') NOT LIKE 'test_overrides,%' THEN
        -- store search path for later
        PERFORM set_config('tests.original_search_path', current_setting('search_path'), true);
        
        -- add tests schema to start of search path
        PERFORM set_config('search_path', 'test_overrides,' || current_setting('tests.original_search_path') || ',pg_catalog', true);
    END IF;

    -- create an overwriting now function
    PERFORM set_config('tests.frozen_time', frozen_time::text, true);

END
$$ LANGUAGE plpgsql;

/**
    * ### tests.unfreeze_time()
    *
    * Unfreezes the time and restores the original now() function.
    *
    * Returns:
    * - void
    *
    * Example:
    * ```sql
    *   SELECT tests.unfreeze_time();
    * ```
 */

CREATE OR REPLACE FUNCTION tests.unfreeze_time()
    RETURNS void
AS $$
BEGIN
    -- restore the original now function
    PERFORM set_config('tests.frozen_time', null, true);
    -- restore the original search path
    PERFORM set_config('search_path', current_setting('tests.original_search_path'), true);
END
$$ LANGUAGE plpgsql;