#!/bin/bash
#
# flush-composer.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Clear composer cache
#

[ -d ~/.composer/cache/ ] && rm -rf ~/.composer/cache/*;

