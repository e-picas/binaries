svn-to-git
==========

A SVN to GIT utility using internal `git-svn`, retrieving *branches* and *tags* and
cleaning the new GIT clone before to push it on a distant remote.

For the original `git-svn` manual, see <http://git-scm.com/docs/git-svn>.

## Usage

    svn-to-git.sh  [--dry-run]  [--test]  [--clean]  [--server-clean]
          [-x | --debug | debug]  [-h | --help | help]  [-i | --usage | usage]
          local_name  [svn_name=local_name]  [git_name=local_name]  [type=none]
          [backup_dirnames=dirA,dirB]  [pre-server-hook]

To begin, run:

    svn-to-git.sh -h

## Environment variables

For a full review of environment variables, run:

    svn-to-git.sh -x

All environment variables are overloadable writing:

    export MSG_GITFILTER="my personal value" && svn-to-git.sh ...

You can take inspiration of the `test.sh` test file included for your own scripts.

## Overview

### Script options

--dry-run
:   show functions call but do not actually run them - default is `false`

--test
:   process all local work but do nothing on distant remote (server) - default is `false`

--clean
:   remove any existing local directory - default is `false`

--server-clean
:   remove any existing directory on distant remote (server) - default is `false`

### Environment variables

#### Local vars

BASE_DIR
:   base working directory to create local clone - default is `tmp/`

DEFAULT_CLEANUP_NAMES
:   array of filenames to remove before any commit - default is:

        .DS_Store .AppleDouble .LSOverride .Spotlight-V100 .Trashes Icon ._* *~ *~lock* 
        Thumbs.db ehthumbs.db Desktop.ini .project .buildpath

#### SVN conf

SVNURL
:   base URL of the SVN repositories - default is `file:///var/svn`

SVNROOT
:   path of the repository to clone from base URL - default is empty

SVN_BRANCH
:   name of special branch for some SVN backups - default is `svn-back`

SVN_PREFIX
:   prefix used for original SVN references in GIT references - default is `svn/`

DELETE_SVN_REMOTES
:   wether to delete original SVN remotes (bool) - default is `false`

#### GIT conf

GITURL
:   base URL of the GIT repositories - default is `file:///var/git`

GITROOT
:   path of the repository to create from base URL - default is empty

GITIGNORE_FILEPATH
:   filepath of a `gitignore` file to add - default is empty

GITIGNORE_FILENAME
:   filename of the `gitignore` file in the clone - default is `.gitignore`

KEEP_IGNOREFILE
:   wether to keep copied `gitignore` in final source code - default is `false`

GITAUTHORS_FILEPATH
:   filepath of an `authors` file to add - default is empty - you can build yours on the model
of the `authors.txt` file

GITAUTHORS_FILENAME
:   filename of the `authors` file in the clone - default is original filename

KEEP_AUTHORSFILE
:   wether to keep copied `authors` in final source code - default is `false`

#### git-svn vars

MSG_GITFILTER
:   a command evaluated to modify all original SVN commit messages - default is empty

ENV_GITFILTER
:   a command evaluated to modify original SVN environment - default is empty

BRANCHES_RECOVERY
:   a command evaluated to extract GIT refs names that must be kept as branches - default is:

        git branch -r | grep -v 'tags/' | grep -v 'trunk' | grep -v 'origin' | sed 's, ,,' | sed 's,branches/,,'

TAGS_RECOVERY
:   a command evaluated to extract GIT refs names that must be kept as tags - default is:

        git branch -r | grep 'tags/' | grep -v '@' | sed 's, ,,'  | sed 's,tags/,,'

NO_METADATA
:   wether to use `--no-metadata` option when re-building SVN history - default is `false`

#### remote server vars

IS_SSH_SERVER
:   wether distant server must be accessed through SSH connection - default is `false`

SERVER
:   URL of the server to push generated clone to - default is empty

## License

Copyright (c) 2013, Piero Wbmstr - All rights reserved. See LICENSE file for infos.

<http://github.com/pierowbmstr/svn-to-git>
