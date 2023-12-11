# Supabase Test Helpers
A collection of functions designed to make testing Supabase projects easier. Created as part of our [open source SaaS starter for Supabase](https://usebasejump.com).

## Quick Start (recommended)
If you're using Supabase:

1) Install dbdev following the instructions here: [github.com/supabase/dbdev](https://github.com/supabase/dbdev)
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

For a basic example, check out the [example blog tests](https://github.com/usebasejump/supabase-test-helpers/blob/main/tests/04-blog-example.sql).

## Manual Installation (not recommended)
Copy the contents of the most recent version into the very first alphabetical test in your test suite, such as `00000-supabase_test_helpers.sql`. This will ensure that the test helpers are removed after your tests have run. for it to work, you need to create some fake tests at the bottom of the file for pgtap to not complain.  Here's an example:
```sql

-- we have to run some tests to get this to pass as the first test file.
-- investigating options to make this better.  Maybe a dedicated test harness
-- but we dont' want these functions to always exist on the database.
BEGIN;

    select plan(7);
    select function_returns('tests', 'create_supabase_user', Array['text', 'text', 'text', 'jsonb'], 'uuid');
    select function_returns('tests', 'get_supabase_uid', Array['text'], 'uuid');
    select function_returns('tests', 'get_supabase_user', Array['text'], 'json');
    select function_returns('tests', 'authenticate_as', Array['text'], 'void');
    select function_returns('tests', 'clear_authentication', Array[null], 'void');
    select function_returns('tests', 'rls_enabled', Array['text', 'text'], 'text');
    select function_returns('tests', 'rls_enabled', Array['text'], 'text');
    select * from finish();
ROLLBACK;
```

## Writing tests
Check out the docs below for available helpers. To view a comprehensive example, check out our [blog tests](https://github.com/usebasejump/supabase-test-helpers/blob/main/tests/04-blog-example.sql).

## Test Helpers
The following is auto-generated off of comments in the `supabase_test_helpers--0.0.2.sql` file. Any changes added to the README directly will be overwritten.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

  - [tests.create_supabase_user(identifier text, email text, phone text)](#testscreate_supabase_useridentifier-text-email-text-phone-text)
  - [tests.get_supabase_user(identifier text)](#testsget_supabase_useridentifier-text)
  - [tests.get_supabase_uid(identifier text)](#testsget_supabase_uididentifier-text)
  - [tests.authenticate_as(identifier text)](#testsauthenticate_asidentifier-text)
  - [tests.authenticate_as_service_role()](#testsauthenticate_as_service_role)
  - [tests.clear_authentication()](#testsclear_authentication)
  - [tests.rls_enabled(testing_schema text)](#testsrls_enabledtesting_schema-text)
  - [tests.rls_enabled(testing_schema text, testing_table text)](#testsrls_enabledtesting_schema-text-testing_table-text)
  - [tests.freeze_time(frozen_time timestamp with time zone)](#testsfreeze_timefrozen_time-timestamp-with-time-zone)
  - [tests.unfreeze_time()](#testsunfreeze_time)
- [Contributing](#contributing)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- include: supabase_test_helpers--0.0.4.sql -->

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

### tests.authenticate_as_service_role()
  Clears authentication object and sets role to service_role.

Returns:
- `void`

Example:
```sql
  SELECT tests.authenticate_as_service_role();
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

### tests.freeze_time(frozen_time timestamp with time zone)

Overwrites the current time from now() to the provided time.

Works out of the box for any normal usage of now(), if you have a function that sets its own search path, such as security definers, then you will need to alter the function to set the search path to include test_overrides BEFORE pg_catalog.
**ONLY do this inside of a pgtap test transaction.**
Example:

```sql
ALTER FUNCTION auth.your_function() SET search_path = test_overrides, public, pg_temp, pg_catalog;
```
View a test example in 05-frozen-time.sql: https://github.com/usebasejump/supabase-test-helpers/blob/main/supabase/tests/05-frozen-time.sql

Parameters:
- `frozen_time` - The time to freeze to. Supports timestamp with time zone, without time zone, date or any other value that can be coerced into a timestamp with time zone.

Returns:
- void

Example:
```sql
  SELECT tests.freeze_time('2020-01-01 00:00:00');
```

### tests.unfreeze_time()

Unfreezes the time and restores the original now() function.

Returns:
- void

Example:
```sql
  SELECT tests.unfreeze_time();
```

<!-- /include: supabase_test_helpers--0.0.4.sql -->

## Contributing
Yes, please! Anything you've found helpful for testing Supabase projects is welcome. To contribute:

* Create a new version of supabase_test_helpers `supabase_test_helpers--{major}-{minor}-{patch}.sql`
* New versions are intended to be a fresh install, so copy the contents of the previous version into the new version.
* Add [pgTAP compliant test functions](https://pgtap.org/documentation.html#composeyourself) to the new version
* Comments should be added above each function, follow the examples in the file.
* Create a migration file `supabase_test_helpers--{oldMajor}-{oldMinor}-{oldPatch}--{newMajor}-{newMinor}-{newPatch}.sql` to upgrade to the new version. Include ONLY your migration code, not the entire contents of the new version.
* Add tests for your functions in `supabase/tests/XX-your-function-name.sql`
* You can verify tests work by running `supabase init` to create a config file, `supabase start` to launch it 
* Install your updated version with `dbdev install --connection postgres://postgres:postgres@localhost:54322/postgres --path .`
* Run `supabase test db` to run the tests.
* Submit a PR