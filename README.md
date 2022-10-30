# Supabase Test Helpers
A collection of functions designed to make testing Supabase projects easier.

## Dependencies
- [Supabase](https://supabase.com)
- [pgTAP](https://pgtap.org/)

<!-- include: supabase_test_helpers.sql -->

### tests.rls_enabled(testing_schema text)
pgTAP function to check if RLS is enabled on all tables in a provided schema

Parameters:
- schema_name text - The name of the schema to check

Example:
```sql
  BEGIN;
      select plan(1);
      select tests.rls_enabled('public');
      SELECT * FROM finish();
  ROLLBACK;
```

## tests.rls_enabled(testing_schema text, testing_table text)
pgTAP function to check if RLS is enabled on a specific table

Parameters:
- schema_name text - The name of the schema to check
- testing_table text - The name of the table to check

Example:
```sql
   BEGIN;
       select plan(1);
       select tests.rls_enabled('public', 'accounts');
       SELECT * FROM finish();
   ROLLBACK;
```

<!-- /include: supabase_test_helpers.sql -->