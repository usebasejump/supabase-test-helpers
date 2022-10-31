BEGIN;

select plan(11);

-- test creating a user
select tests.create_supabase_user('testuser');
select tests.create_supabase_user('testuser2', 'testuser2@test.com');
select tests.create_supabase_user('testuser3', null, '555-555-5555');

select is((select count(*)::integer from auth.users), 3, 'create_supabase_user should have created 3 users');

select is((select tests.get_supabase_user('testuser')), (select id from auth.users where raw_user_meta_data ->> 'test_identifier' = 'testuser'), 'get_supabase_user should return a user');
select throws_ok($$ select tests.get_supabase_user('testuser4') $$, 'User with identifier testuser4 not found');

-- should not mess with transactions current role
set role anon;
select ok((select tests.create_supabase_user('testuser5') is not null), 'create_supabase_user should be callable by any test role');
select throws_ok($$ select * from auth.users$$, 'permission denied for table users');
select ok((select tests.get_supabase_user('testuser2') IS NOT NULL), 'get_supabase_user should return a user for anon role');
-- make sure we're still anon
select is((select current_role::text), 'anon', 'current_role should still be anon');

set role authenticated;
select ok((select tests.create_supabase_user('testuser5') is not null), 'create_supabase_user should be callable by any test role');
select throws_ok($$ select * from auth.users$$, 'permission denied for table users');
select ok((select tests.get_supabase_user('testuser2') IS NOT NULL), 'get_supabase_user should return a user for anon role');
-- make sure we're still anon
select is((select current_role::text), 'authenticated', 'current_role should still be anon');
select * from finish();

ROLLBACK;