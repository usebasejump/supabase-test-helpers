# Supabase Test Helpers
A collection of functions designed to make testing Supabase projects easier. Created as part of our [open source SaaS starter for Supabase](https://usebasejump.com).

## Quick Start
If you're using Supabase:

1) Install dbdev following the instructions here: [github.com/supabase/dbdev](github.com/supabase/dbdev)
2) Install the test helpers as an extension:

```sql
select dbdev.install('basejump-supabase_test_helpers');
```

I don't recommend activating the extension in production directly, instead you can activate it as part of your test suite.  For example:

```sql
BEGIN;
CREATE EXTENSION "basejump-supabase_test_helpers";

select plan(1);
-- create a table, which will have RLS disabled by default
CREATE TABLE public.tb1 (id int, data text);
ALTER TABLE public.tb1 ENABLE ROW LEVEL SECURITY;

-- test to make sure RLS check works
select check_test(tests.rls_enabled('public', 'tb1'), true);

SELECT * FROM finish();
ROLLBACK;
```

For a basic example, check out the [example blog tests](tests/04-blog-example.sql).

## Manual Installation
Copy the contents of `supabase_test_helpers.sql` into the very first alphabetical test in your test suite, such as `00000-supabase_test_helpers.sql`. This will ensure that the test helpers are removed after your tests have run.

## Writing tests
Check out the docs below for available helpers. To view a comprehensive example, check out our [blog tests](tests/04-blog-example.sql).

## Contributing
Yes, please! Anything you've found helpful for testing Supabase projects is welcome. To contribute:

* Add [pgTAP compliant test functions](https://pgtap.org/documentation.html#composeyourself) to `supabase_test_helpers.sql`
* Comments should be added above each function, follow the examples in the file.
* Add tests for your functions in `tests/XX-your-function-name.sql`
* Submit a PR

## Test Helpers
The following is auto-generated off of comments in the `supabase_test_helpers.sql` file. Any changes added to the README directly will be overwritten.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [tests.create_supabase_user(identifier text, email text, phone text)](#testscreate_supabase_useridentifier-text-email-text-phone-text)
- [tests.get_supabase_user(identifier text)](#testsget_supabase_useridentifier-text)
- [tests.get_supabase_uid(identifier text)](#testsget_supabase_uididentifier-text)
- [tests.authenticate_as(identifier text)](#testsauthenticate_asidentifier-text)
- [tests.clear_authentication()](#testsclear_authentication)
- [tests.rls_enabled(testing_schema text)](#testsrls_enabledtesting_schema-text)
- [tests.rls_enabled(testing_schema text, testing_table text)](#testsrls_enabledtesting_schema-text-testing_table-text)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- include: supabase_test_helpers.sql -->

### tests.create_supabase_user(identifier text, email text, phone text)

Creates a new user in the `auth.users` table.
You can recall a user's info by using `tests.get_supabase_user(identifier text)`.

Parameters:
- `identifier` - A unique identifier for the user. We recommend you keep it memorable like "test_owner" or "test_member"
- `email` - (Optional) The email address of the user
- `phone` - (Optional) The phone number of the user
- `metadata` - (Optional) Additional metadata to be added to the user

Returns:
- `user_id` - The UUID of the user in the `auth.users` table

Example:
```sql
  SELECT tests.create_supabase_user('test_owner');
  SELECT tests.create_supabase_user('test_member', 'member@test.com', '555-555-5555');
  SELECT tests.create_supabase_user('test_member', 'member@test.com', '555-555-5555', '{"key": "value"}'::jsonb);
```

### tests.get_supabase_user(identifier text)

Returns the user info for a user created with `tests.create_supabase_user`.

Parameters:
- `identifier` - The unique identifier for the user

Returns:
- `user_id` - The UUID of the user in the `auth.users` table

Example:
```sql
  SELECT posts where posts.user_id = tests.get_supabase_user('test_owner') -> 'id';
```

### tests.get_supabase_uid(identifier text)

Returns the user UUID for a user created with `tests.create_supabase_user`.

Parameters:
- `identifier` - The unique identifier for the user

Returns:
- `user_id` - The UUID of the user in the `auth.users` table

Example:
```sql
  SELECT posts where posts.user_id = tests.get_supabase_uid('test_owner') -> 'id';
```

### tests.authenticate_as(identifier text)
  Authenticates as a user created with `tests.create_supabase_user`.

Parameters:
- `identifier` - The unique identifier for the user

Returns:
- `void`

Example:
```sql
  SELECT tests.create_supabase_user('test_owner');
  SELECT tests.authenticate_as('test_owner');
```

### tests.clear_authentication()
  Clears out the authentication and sets role to anon

Returns:
- `void`

Example:
```sql
  SELECT tests.create_supabase_user('test_owner');
  SELECT tests.authenticate_as('test_owner');
  SELECT tests.clear_authentication();
```

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
