function fish_prompt
	powerline-go -shell bare
end

set -gx EDITOR nvim
set -gx TERMINAL kitty
set -gx BROWSER firefox

set -gx PATH $PATH ~/.bin
set -gx QT_QPA_PLATFORMTHEME qt5ct

# aliases
source ~/.config/fish/alias.fish

# kitty
kitty + complete setup fish | source

# goenv
# set -gx GOENV_ROOT $HOME/.goenv
# set -gx PATH $PATH $GOENV_ROOT/bin
# source (goenv init - | psub)

# luarocks
eval (luarocks path --bin)

# pyenv
# set -gx PYENV_ROOT $HOME/.goenv
# set -gx PATH $PATH PYENV_ROOT/bin
# source (pyenv init - | psub)

neofetch