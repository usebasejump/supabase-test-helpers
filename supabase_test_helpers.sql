
-- We want to store all of this in the tests schema to keep it
-- separate from any application data
create if not defined schema tests;

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
RETURNS TEXT AS $$
DECLARE
    result BOOLEAN;
BEGIN
    return is_empty(
        $$ select
           	pn.nspname,
           	pc.relname,
           	pc.relrowsecurity,
           	pc.relforcerowsecurity
           from pg_class pc
           join pg_namespace pn on pn.oid = pc.relnamespace and pn.nspname = testing_schema
           join pg_type pt on pt.oid = pc.reltype
           where relrowsecurity = FALSE $$,
        'All tables in the' || testing_schema || ' schema should have row level security enabled'
    )
END;
$$ LANGUAGE plpgsql;

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
DECLARE
    result BOOLEAN;
BEGIN
    return is_empty(
        $$ select
           	pn.nspname,
           	pc.relname,
           	pc.relrowsecurity,
           	pc.relforcerowsecurity
           from pg_class pc
           join pg_namespace pn on pn.oid = pc.relnamespace and pn.nspname = testing_schema and pc.relname = testing_table
           join pg_type pt on pt.oid = pc.reltype
           where relrowsecurity = FALSE $$,
        'All tables in the' || testing_schema || ' schema should have row level security enabled'
    )
END;
$$ LANGUAGE plpgsql;