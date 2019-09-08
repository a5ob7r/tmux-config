source ~/.tmux/tmux.lib.sh

# {{{ default shell
tmux set -g default-command "$SHELL"
# }}}

# {{{ terminal type
# use true color in tmux
tmux set -g default-terminal "xterm-256color"
tmux set -ga terminal-overrides ",xterm-256color:Tc"
# }}}

# {{{ operating style
tmux set -g mouse on
tmux set -wg mode-keys vi
tmux set -g status-keys emacs
tmux set -sg escape-time 0
# }}}

# {{{ status line
if ! is_ssh_connection; then
  tmux set -g status-position top
fi
# }}}

# {{{ history
tmux set -g history-file "$HOME/.tmux_history"
tmux set -g history-limit 10000
# }}}

# {{{ command alias
if is_tmux_version "> 2.4"; then
  tmux set -sg command-alias[0] e="split-window -c '#{pane_current_path}'"
fi
# }}}

# {{{ others
tmux set -wg aggressive-resize on
# }}}
