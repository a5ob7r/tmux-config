#!/usr/bin/env bash

# Set current tmux version on an environment variable to control tmux
# conficures per tmux version
is_tmux_version() {
  # conditional expression
  # ex. "= 1.9", "> 2.9"
  local cond_expr="${1}"

  # current tmux version
  local tmux_version
  tmux_version="$(tmux -V | sed 's/tmux \(next-\)*//g')"

  [[ "$(bc <<< "${tmux_version} ${cond_expr}")" == 1 ]]
}

is_ssh_connection() {
  [[ -n "${SSH_CONNECTION}" ]]
}

# {{{ prefix key
readonly TMUX_PREFIX_KEY='C-q'
tmux set -g prefix "${TMUX_PREFIX_KEY}"
tmux bind "${TMUX_PREFIX_KEY}" send-prefix
tmux unbind 'C-b'
# }}}

if is_tmux_version "> 2.4"; then
  tmux bind -T copy-mode-vi v send-keys -X begin-selection
  tmux bind -T copy-mode-vi V send-keys -X select-line
fi
# }}}

# {{{ pane control
# when split window, the directory on new splitted window is same on original window.
tmux unbind "%"
tmux bind "%" split-window -h -c "#{pane_current_path}"
tmux unbind '"'
tmux bind '"' split-window -v -c "#{pane_current_path}"

# move pane with operation like vim
tmux bind k select-pane -U
tmux bind j select-pane -D
tmux bind h select-pane -L
tmux bind l select-pane -R
# }}}

# {{{ other
tmux bind r "source-file ~/.tmux.conf; display '.tmux.conf is reloaded!'"

# Jump to previous prompt of pure
tmux bind B "copy-mode; send-keys -X search-backward '❯'; send-keys -X search-again"

# make mouse wheel smoother
if is_tmux_version "> 2.4"; then
  tmux bind -T copy-mode-vi WheelUpPane   send-keys -X scroll-up
  tmux bind -T copy-mode-vi WheelDownPane send-keys -X scroll-down
fi
# }}}

# {{{ commnad alias
# exec man by split window
tmux bind m command-prompt -p "<manual by split-window horiz>" "split-window 'exec man %%'"
tmux bind M command-prompt -p "<manual by split-window vert>" "split-window -h 'exec man %%'"

# exec tig
tmux bind g split-window -c "#{pane_current_path}" tig
# }}}

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
