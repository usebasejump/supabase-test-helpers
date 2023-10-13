-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION supabase_test_helpers" to load this file. \quit

/**
    * ### tests.authenticate_as_service_role()
    *   Clears authentication object and sets role to service_role.
    *
    * Returns:
    * - `void`
    *
    * Example:
    * ```sql
    *   SELECT tests.authenticate_as_service_role();
    * ```
 */
CREATE OR REPLACE FUNCTION tests.authenticate_as_service_role ()
    RETURNS void
    AS $$
        BEGIN
            perform set_config('role', 'service_user', true);
            perform set_config('request.jwt.claims', null, true);
        END
    $$ LANGUAGE plpgsql;