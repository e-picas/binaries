cleanup
=======

A simple shell utility to fix UNIX rights on files, directories, secret files and binaries
and to clean up OS files on a working directory.

## Usage

    cleanup.sh  [-h | --help | help]  [-i | --usage | usage]
          [-x | --dry-run]  [-v | --verbose]  [-q | --quiet]
          [-d | --chmod-dirs =CHMOD]  [-f | --chmod-files =CHMOD]
          [-a | --chmod-secret =CHMOD]  [-b | --chmod-bins =CHMOD]
          [-s | --shells =MASKS LIST]  [-z | --bin =BIN DIRS LIST]
          [-m | --mask =MASKS LIST]  [-k | --keys =MASKS LIST]

To begin, run:

    cleanup.sh -h

## License

Copyright (c) 2013, Piero Wbmstr - All rights reserved. See LICENSE file for infos.

<http://github.com/pierowbmstr/cleanup>
