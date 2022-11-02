BEGIN;

select plan(7);

select tests.create_supabase_user('test');

select throws_ok($$ select tests.authenticate_as('test-fake') $$, 'User with identifier test-fake not found'::text);
select lives_ok($$ select tests.authenticate_as('test') $$, 'Successfully authenticated as test user');

select is((select tests.get_supabase_uid('test')), auth.uid(), 'Authenticates as the correct user');
select is((select current_role::text), 'authenticated', 'Sets the current role to authenticated');

select lives_ok($$ select tests.clear_authentication() $$, 'should clear authentication');
select is((select current_role::text), 'anon', 'Sets the current role to anonymous');
select is((select auth.uid()), null, 'Clears out authentication');

select * from finish();
ROLLBACK;