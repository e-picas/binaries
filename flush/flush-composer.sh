#!/bin/bash
#
# flush-composer.sh
# by @picas (me at picas dot fr)
# <http://github.com/e-picas/binaries.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Clear composer cache
#

[ -d ~/.composer/cache/ ] && rm -rf ~/.composer/cache/*;

