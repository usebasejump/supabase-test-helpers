BEGIN;
-- TODO: For now you have to specify the version due to a bug in pg_tle
-- this should be changed to remove the version once the bug is fixed
-- right now it always installs the FIRST version of the extension
CREATE EXTENSION supabase_test_helpers version '0.0.4';

select plan(12);

-- create a posts table that references the auth.users table
create table public.posts
(
    -- post id
    id uuid primary key default uuid_generate_v4(),
    -- the user's ID from the auth.users table out of supabase
    user_id         uuid references auth.users not null default auth.uid(),
    -- post content
    content       text
);

-- won't be protected by default
select check_test(tests.rls_enabled('public', 'posts'), false);


-- Setup RLS on the posts table
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

create policy "All users can view their own posts" on public.posts
    for select
    to authenticated
    using (
        true
    );

create policy "Users can create their own posts" on public.posts
    for insert
    to authenticated
    with check (
        user_id = auth.uid()
    );

create policy "Users can update their own posts" on public.posts
    for update
    to authenticated
    using (
        user_id = auth.uid()
    );

create policy "Users can delete their own posts" on public.posts
    for delete
    to authenticated
    using (
        user_id = auth.uid()
    );

-- RLS should be enabled now with policies in place
-- Let's give it a test!

select tests.create_supabase_user('post_owner');
select tests.create_supabase_user('post_viewer');

-----------
-- Acting as post_owner
-----------
select tests.authenticate_as('post_owner');

-- insert a post
SELECT
    results_eq(
        $$ insert into public.posts (content) values ('Post created') returning user_id $$,
        $$ VALUES(tests.get_supabase_uid('post_owner')) $$,
        'authenticated users can insert a post'
        );

-- owner can view their own posts
SELECT
    results_eq(
            $$ select content from posts limit 1 $$,
            $$ VALUES('Post created') $$,
            'Post owners can view their own posts'
        );

-- owner can update the post
SELECT
    results_eq(
            $$ update posts set content = 'Post updated' returning content $$,
            $$ VALUES('Post updated') $$,
            'Post owners can update their own posts'
        );

----------
-- Acting as post_viewer
----------
SELECT tests.authenticate_as('post_viewer');

-- post viewer cannot update the post
SELECT
    is_empty(
            $$ update posts set content = 'Post updated by viewer' returning content $$,
            'Post viewers cannot update posts'
        );

-- post viewer cannot delete the post
SELECT
    is_empty(
            $$ delete from posts returning 1 $$,
            'Post viewers cannot delete posts'
        );

-- post viewer can view the post
SELECT
    results_eq(
            $$ select content from posts limit 1 $$,
            $$ VALUES('Post updated') $$,
            'Post owners can view their own posts'
        );

---------
-- Acting as anon
---------
SELECT tests.clear_authentication();

-- anon cannot view the post
SELECT
    is_empty(
            $$ select * from posts $$,
            'Anon cannot view posts'
        );

-- anon cannot update the post
SELECT
    is_empty(
            $$ update posts set content = 'Post updated by viewer' returning content $$,
            'Anon cannot update posts'
        );

-- anon cannot delete the post
SELECT
    is_empty(
            $$ delete from posts returning 1 $$,
            'Anon cannot delete posts'
        );

-- anon cannot insert new posts
SELECT
    throws_ok(
            $$ insert into posts (content) values ('Post created by anon') $$,
            'new row violates row-level security policy for table "posts"'
        );

--------
-- Acting as post_owner
--------
SELECT tests.authenticate_as('post_owner');

-- post owner can delete the post
SELECT
    results_eq(
            $$ delete from posts returning 1 $$,
            $$ VALUES(1) $$,
            'Post owners can delete their own posts'
        );

select * from finish();

ROLLBACK;