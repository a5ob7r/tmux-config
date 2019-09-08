 is_tmux_version() {
   # conditional expression
   # ex. "= 1.9", "> 2.9"
  local cond_expr=$1

  # current tmux version
  local tmux_version
  tmux_version=$(tmux -V | sed 's/[a-zA-z -]//g')

  [[ "$(echo "${tmux_version} ${cond_expr}" | bc)" = 1 ]]
}

is_ssh_connection() {
  [[ -n "$SSH_CONNECTION" ]]
}
