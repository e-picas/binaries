binaries
========

My personal *NIX binaries, licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>

In addition, my personal *dotfiles* are hosted at <http://github.com/e-picas/dotfiles>.


## Installation

Create the clone and symlink all binaries in current user's `bin/`:

    git clone https://github.com/e-picas/binaires.git ~/binaries
    cd ~/binaires
    find * -name "*.sh" -exec ln -s `pwd`/{} ~/bin/ \;


----

Author: Pierre Cassat - @picas (me at picas dot fr)

Original sources: <http://github.com/e-picas/binaries.git>

License: CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
