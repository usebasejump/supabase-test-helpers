# Supabase Test Helpers
A collection of functions designed to make testing Supabase projects easier.

## Installation
Copy the contents of `supabase_test_helpers.sql` into your supabase query interface and run it.

Alternatively, you can generate a migration file and add it there.

## Contributing
Yes, please! Anything you've found helpful for testing Supabase projects is welcome. To contribute, please add [pgTAP compliant test functions](https://pgtap.org/documentation.html#composeyourself) to `supabase_test_helpers.sql` and submit a PR. Comments should be added above each function, follow the examples in the file.

## Test Helpers
The following is auto-generated off of comments in the `supabase_test_helpers.sql` file. Any changes added to the README directly will be overwritten.

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

### tests.rls_enabled(testing_schema text, testing_table text)
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