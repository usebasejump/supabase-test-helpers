#!/bin/bash

# For testing purposes we need to create a supabase_test_helpers_pglet.sql version of the most recent supabase_test_helpers.sql file
# pglet extensions have the following format:
# SELECT pgtle.install_extension
# (
#  'supabase_test_helpers',
#  '0.1',
#   'pgTAP test helpers for interacting with Supabase, including RLS and Authentication',
# $_pg_tle_$
# {extension_code}
# $_pg_tle_$
# );

# This script will create a supabase_test_helpers_pglet.sql file with the extension code only

MOST_RECENT_VERSION=$(grep default_version ./supabase_test_helpers.control | cut -d'=' -f2 | tr -d ' ')

# Get the extension code
EXTENSION_CODE=$(cat ./supabase_test_helpers--${MOST_RECENT_VERSION}.sql)

# Create the supabase_test_helpers_pglet.sql file
echo "SELECT pgtle.install_extension
(
 'supabase_test_helpers',
 '${MOST_RECENT_VERSION}',
  'pgTAP test helpers for interacting with Supabase, including RLS and Authentication',
\$_pg_tle_$
${EXTENSION_CODE}
\$_pg_tle_$
);" > ./supabase_test_helpers_pglet.sql

