# Setup fzf
# ---------
if [[ ! "$PATH" == *$HOME/.stowed/fzf/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}$HOME/.stowed/fzf/.fzf/bin"
fi

source <(fzf --zsh)