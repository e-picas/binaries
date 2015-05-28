#!/usr/bin/env bash
#
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# generate-salt.sh : generates random salt strings or passwords
#
set -e

# presets
declare -a presets
declare -a presets_mask
declare -a presets_length
# simple num
presets+=( num )
presets_mask+=( '0-9' )
presets_length+=( 8 )
# upper alpha
presets+=( upperalpha )
presets_mask+=( 'A-Z' )
presets_length+=( 10 )
# lower alpha
presets+=( loweralpha )
presets_mask+=( 'a-z' )
presets_length+=( 10 )
# alpha
presets+=( alpha )
presets_mask+=( 'A-Za-z' )
presets_length+=( 12 )
# alphanum
presets+=( alphanum )
presets_mask+=( 'A-Za-z0-9' )
presets_length+=( 12 )
# basic
presets+=( basic )
presets_mask+=( 'A-Za-z0-9#!$*@&%' )
presets_length+=( 16 )
# hard
presets+=( hard )
presets_mask+=( 'A-Za-z0-9#!$*@&%\-+=\/.,:;?()[]^`' )
presets_length+=( 64 )

# usage string
usage() {
    {   echo "usage: $0 <preset> [length=default]"
        echo "available presets:"
        printf "\t%13s\t%s\t%-30s" 'name' 'length' 'mask'
        printf "\n\t%13s\t%s\t%-30s" '----------' '------' '----'
        for pre in "${!presets[@]}"; do
            printf "\n\t%13s\t%-6d\t%-30s" \
                "${presets[$pre]} :" "${presets_length[$pre]}" "${presets_mask[$pre]}";
        done
        echo
        echo '---'
        echo "e.g. $0 alpha      : dlNMPuMhfXCG"
        echo "     $0 basic 18   : VjO23Jv4K@2&sLwUF4"
        echo "     $0 hard 64    : vDm@UMG%5+CKsgY5xJX]jA(WtsN^8Ik;/,k6mFW.qNRvq(bf(WM+E2tGaR\`R(m@]"
    } >&2
    exit 1
}

# arg required
if [ -z "$1" ]; then
    usage
fi

# generation
preset="${1}"
index=''
for key in "${!presets[@]}"; do
    if [ "${presets[$key]}" = "$preset" ]; then
        index="$key"
    fi
done
if [ -z "$index" ]; then
    echo "> preset '$preset' not found!" >&2
    echo '---'
    usage
fi
mask="${presets_mask[$index]}"
length="${2:-${presets_length[$index]}}"
#echo "> preset: ${preset}"
#echo "> index:  ${index}"
#echo "> mask:   ${mask}"
#echo "> length: ${length}"
tr -dc "$mask" < /dev/urandom | head -c "$length" | xargs

exit 0
# Endfile
# vim: autoindent tabstop=4 shiftwidth=4 expandtab softtabstop=4 filetype=sh
