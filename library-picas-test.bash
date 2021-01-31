#!/bin/bash
#
# This is a (simple) Bash script model
# 
# Some '[man]' strings are present in the comments to identify #@!
# what to do to turn this template to your own script.
# See the bottom of the file for a longer documentation.
# Released into the public domain (see the bottom of the file for more info)
# by Picas <me[at]picas.fr>
#
set -e

#######################################################################
## [man] the required Library 
source library-picas.bash || ( echo 'Required library-picas.bash not found in PATH or locally'; exit 1; );

#######################################################################
## [man] Default flags
VERBOSE=0
DRYRUN=false
DEVDEBUG=false
LOGGING=true
LOGFILE="$0.log"

## [man] Script infos
# the script name
SCRIPT_NAME="$(basename $0)"
# the version number - you must increase it and follow the semantic versioning standards <https://semver.org/>
SCRIPT_VERSION="0.0.1-dev"
# a short presentation about the purpose of the script
SCRIPT_PRESENTATION=$(cat <<EOT
This software is a (simple) Bash script model (see <https://tldp.org/LDP/abs/html/>)
using the 'library-picas.bash' library of functions
You can use it as a template or an help for your own scripts.
You may work on the source code to see how to use it...
EOT
);
# an information displayed with the version number: authoring, licensing etc
SCRIPT_LICENSE=$(cat <<EOT
$LD_SCRIPT_LICENSE
EOT
);
# a quick usage string, complete but concise
SCRIPT_USAGE_SHORT=$(cat <<EOT
$LD_SCRIPT_USAGE_SHORT
EOT
);
# the long helping string explaining how to use the script
SCRIPT_USAGE=$(cat <<EOT
$LD_SCRIPT_USAGE
EOT
);
export SCRIPT_USAGE

#######################################################################
## [man] System settings

# trap a signal and throw it to 'error_dev ()'
# trapped signals:
#   errors (ERR)
#   script exit (EXIT)
#   interrupt (SIGINT)
#   terminate (SIGTERM)
#   kill (KILL)
trap 'error_dev $?' ERR
trap 'error_interrupt $?' SIGINT

#######################################################################
## [man] Arguments, parameters & options

# if arguments are required
[ $# -eq 0 ] && error_throw 'arguments are required';

# # arguments
# ARGS_ORIG="$*"
# while [ $# -gt 0 ]; do
#     ARG_PARAM="$(cut -d'=' -f2 <<< "$1")"
#     case "$1" in
# #_opts_#
# ## this is used to generate a list of available options
#         # user options...
#         --option=*) VAR="$ARG_PARAM" ;; # to do what ?

#         # you should NOT change below
#         -h|--help) get_help ;; # display help string
#         -V|--version) get_version ;; # display version string
#         -v|--verbose) VERBOSE=$((VERBOSE + 1)) ;; # increase verbosity
#         -q|--quiet) VERBOSE=$((VERBOSE - 1)) ;; # decrease verbosity
#         --dry-run|--check) DRYRUN=true ;; # enable "dry-run" mode (nothing is actually done)

#         # these are mostly for the library
#         --manual) get_manual ;; # display manual
#         --options) get_options_list ;; # display options list
#         # for development...
#         -x|--debug) DEVDEBUG=true ;; # enable debug mode
#         -l|--log) LOGGING=true ;; # enable logging
#         --log-file=*) LOGFILE="$ARG_PARAM" ;; # set logfile path
# #_opts_#
#         -*) error_throw "unknown option '$1'" ;;
#         *) break ;;
#     esac
#     shift
# done
# export VERBOSE DRYRUN DEVDEBUG SCRIPT_STATUS LOGGING LOGFILE

#######################################################################
## [man] Let's go for scripting ;)
log_write 'info' "starting run with params: $ARGS_ORIG"

      # throws a classic 'usage' error
      # error_throw 'test error...'
      
      # throws a development error with a stack trace
      # error_dev 'test dev error...'
      
      # test error trapping
      # cmd_not_found
      
      # this will only write 'test verbosity...' if the '--verbose' option is used
      # echo_verbose 'test verbosity...'
      
      # write a string to the logs
      # log_write info 'test log'

# sleep 10

$DEVDEBUG && debug;
echo '-- end of script'
exit 0

#######################################################################
## [man] Script ends here - anything below is documentation and not executed #@!
# vim: autoindent tabstop=4 shiftwidth=4 expandtab softtabstop=4 filetype=sh
