# match-count-statusline.vim

This plugin provides one relatively simple piece of functionality to
Vim: it automatically counts the number of times the current search
pattern occurs in your current buffer and displays that in the
statusline.

![Screenshot showing match counting in Airline][example]

It tries to do the right thing and otherwise stay out of the way, but it
is configurable. To use it, install it, and it ought to add itself to
your statusline automatically. It understands how to add itself to the
vanilla statusline and to [vim-airline].

If you need to customize where or how it is added to your statusline,
add `%{MatchCountStatusline()}` in your statusline from within your
`~/.vimrc`, and match-count-statusline.vim will not attempt to override
your setting.

For more information, run `:help match-count-statusline` from within Vim
after installing this plugin.


## Installing

This plugin requires a version of vim of 7.4.1658 or greater. It may be
installed any of the usual ways. Below are the suggested ways for
[Pathogen] and Vim 8's own built-in package method.


### Pathogen

If you're using venerable [Pathogen], clone this directory to your
bundles.

    git clone https://github.com/emilyst/match-count-statusline.git \
      ~/.vim/bundle/match-count-statusline


### Vim Packages

This is also installable as a Vim package (see `:help packages`) if
you're running a version of Vim greater than or equal to 8.

Vim's internal package management expects packages in the future to
include a "`start`" and an "`opt`" directory to contain its runtime
paths. As with almost every plugin written in the last decade, I have
not written mine like this. Therefore, you will need to put the entire
plugin under some arbitrary "`start`" directory whose name you probably
have already have chosen (and which doesn't matter). In the below
example, I call this directory "`default`."

    git clone https://github.com/emilyst/match-count-statusline.git \
      ~/.vim/pack/default/start/match-count-statusline


[example]: example.png
[vim-airline]: https://github.com/vim-airline/vim-airline
[Pathogen]: https://github.com/tpope/vim-pathogen
