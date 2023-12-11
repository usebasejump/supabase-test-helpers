BEGIN;

CREATE EXTENSION supabase_test_helpers;

select plan(9);

select tests.create_supabase_user('test');

select throws_ok($$ select tests.authenticate_as('test-fake') $$, 'User with identifier test-fake not found'::text);
select lives_ok($$ select tests.authenticate_as('test') $$, 'Successfully authenticated as test user');

select is((select tests.get_supabase_uid('test')), auth.uid(), 'Authenticates as the correct user');
select is((select current_role::text), 'authenticated', 'Sets the current role to authenticated');
select is(
	current_setting('request.jwt.claims')::jsonb ?& array['sub', 'email', 'phone', 'user_metadata', 'app_metadata'], 
  true,
	'Claims should contain correct keys for authenticated user'
	);

select lives_ok($$ select tests.clear_authentication() $$, 'should clear authentication');
select is((select current_role::text), 'anon', 'Sets the current role to anonymous');
select is((select auth.uid()), null, 'Clears out authentication');
select is(
	current_setting('request.jwt.claims'), 
	'', 
	'Empties request claims'
	);

select * from finish();
ROLLBACK;