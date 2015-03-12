binaries
========

My personal *NIX binaries, licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>

In addition, my personal *dotfiles* are hosted at <http://github.com/piwi/dotfiles>.


## Installation

Create the clone and symlink all binaries in current user's `bin/`:

    git clone https://github.com/piwi/binaires.git ~/binaries
    cd ~/binaires
    find * -name "*.sh" -exec ln -s `pwd`/{} ~/bin/ \;


----

Author: Pierre Cassat - @piwi (me at e-piwi dot fr)

Original sources: <http://github.com/piwi/binaries.git>

License: CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
