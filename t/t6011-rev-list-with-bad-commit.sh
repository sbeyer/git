#!/bin/sh

test_description='git rev-list should notice bad commits'

. ./test-lib.sh

# Note:
# - compression level is set to zero to make "corruptions" easier to perform
# - reflog is disabled to avoid extra references which would twart the test

test_expect_success 'setup' \
   '
   git init &&
   git config core.compression 0 &&
   git config core.logallrefupdates false &&
   test_commit_add_line foo foo &&
   test_commit_add_line -m "second commit" bar bar &&
   test_commit_add_line baz baz &&
   test_commit_add_line "foo again" foo &&
   git repack -a -f -d
   '

test_expect_success 'verify number of revisions' \
   '
   revs=$(git rev-list --all | wc -l) &&
   test $revs -eq 4 &&
   first_commit=$(git rev-parse HEAD~3)
   '

test_expect_success 'corrupt second commit object' \
   '
   perl -i.bak -pe "s/second commit/socond commit/" .git/objects/pack/*.pack &&
   test_must_fail git fsck --full
   '

test_expect_success 'rev-list should fail' \
   '
   test_must_fail git rev-list --all > /dev/null
   '

test_expect_success 'git repack _MUST_ fail' \
   '
   test_must_fail git repack -a -f -d
   '

test_expect_success 'first commit is still available' \
   '
   git log $first_commit
   '

test_done

