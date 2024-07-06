# Setup fzf
# ---------
if [[ ! "$PATH" == */home/badaniya/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/badaniya/.fzf/bin"
fi

eval "$(fzf --bash)"
