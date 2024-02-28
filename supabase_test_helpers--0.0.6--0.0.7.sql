/**
    * ### tests.authenticate_as(identifier text)
    *   Authenticates as a user created with `tests.create_supabase_user`.
    *
    * Parameters:
    * - `identifier` - The unique identifier for the user
    *
    * Returns:
    * - `void`
    *
    * Example:
    * ```sql
    *   SELECT tests.create_supabase_user('test_owner');
    *   SELECT tests.authenticate_as('test_owner');
    * ```
 */
CREATE OR REPLACE FUNCTION tests.authenticate_as (identifier text)
    RETURNS void
    AS $$
        DECLARE
user_data json;
                original_auth_data text;
BEGIN
            -- store the request.jwt.claims in a variable in case we need it
            original_auth_data := current_setting('request.jwt.claims', true);
            user_data := tests.get_supabase_user(identifier);

            if user_data is null OR user_data ->> 'id' IS NULL then
                RAISE EXCEPTION 'User with identifier % not found', identifier;
end if;


            perform set_config('role', 'authenticated', true);
            perform set_config('request.jwt.claims', json_build_object(
                'sub', user_data ->> 'id',
                'email', user_data ->> 'email',
                'phone', user_data ->> 'phone',
                'user_metadata', user_data -> 'raw_user_meta_data',
                'app_metadata', user_data -> 'raw_app_meta_data',
                'exp', extract(epoch from (current_timestamp + interval '1 hour'))
            )::text, true);

EXCEPTION
            -- revert back to original auth data
            WHEN OTHERS THEN
                set local role authenticated;
set local "request.jwt.claims" to original_auth_data;
RAISE;
END
    $$ LANGUAGE plpgsql;