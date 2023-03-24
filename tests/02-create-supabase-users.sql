BEGIN;

select plan(14);

-- test creating a user
select tests.create_supabase_user('testuser');
select tests.create_supabase_user('testuser2', 'testuser2@test.com');
select tests.create_supabase_user('testuser3', null, '555-555-5555');
select tests.create_supabase_user('testuser4', null, null, '{"has": "json"}'::jsonb);

select is((select count(*)::integer from auth.users), 4, 'create_supabase_user should have created 4 users');

select is((select tests.get_supabase_uid('testuser')), (select id from auth.users where raw_user_meta_data ->> 'test_identifier' = 'testuser'), 'get_supabase_uid should return a user');
select is((select (tests.get_supabase_user('testuser') ->> 'id')::uuid), (select id from auth.users where raw_user_meta_data ->> 'test_identifier' = 'testuser'), 'get_supabase_user should return a user id');
select is((select tests.get_supabase_user('testuser2') ->> 'email'), (select email::text from auth.users where raw_user_meta_data ->> 'test_identifier' = 'testuser2'), 'get_supabase_user should return a user email');
select is((select tests.get_supabase_user('testuser3') ->> 'phone'), (select phone::text from auth.users where raw_user_meta_data ->> 'test_identifier' = 'testuser3'), 'get_supabase_user should return a user phone');
select is((select tests.get_supabase_user('testuser3') ->> 'raw_user_metadata' ->> 'has'), (select raw_user_metadata ->> 'has' from auth.users where raw_user_meta_data ->> 'test_identifier' = 'testuser4'), 'get_supabase_user should return custom metadata');
select throws_ok($$ select tests.get_supabase_user('testuser5') $$, 'User with identifier testuser5 not found');

-- should not mess with transactions current role
set role anon;
select ok((select tests.create_supabase_user('testuser5') is not null), 'create_supabase_user should be callable by any test role');
select throws_ok($$ select * from auth.users$$, 'permission denied for table users');
select ok((select tests.get_supabase_uid('testuser2') IS NOT NULL), 'get_supabase_user should return a user for anon role');
-- make sure we're still anon
select is((select current_role::text), 'anon', 'current_role should still be anon');

set role authenticated;
select ok((select tests.create_supabase_user('testuser5') is not null), 'create_supabase_user should be callable by any test role');
select throws_ok($$ select * from auth.users$$, 'permission denied for table users');
select ok((select tests.get_supabase_uid('testuser2') IS NOT NULL), 'get_supabase_user should return a user for anon role');
-- make sure we're still anon
select is((select current_role::text), 'authenticated', 'current_role should still be anon');
select * from finish();

ROLLBACK;
