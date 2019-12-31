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

readonly TMUX_DATA_HOME_PATH=~/.local/share/tmux
readonly TMUX_PLUGIN_MANAGER_PATH="${TMUX_DATA_HOME_PATH}/plugins"

tmux setenv -g TMUX_PLUGIN_MANAGER_PATH "${TMUX_PLUGIN_MANAGER_PATH}"

# {{{ prefix key
readonly TMUX_PREFIX_KEY='C-q'
tmux set -g prefix "${TMUX_PREFIX_KEY}"
tmux bind "${TMUX_PREFIX_KEY}" send-prefix
tmux unbind 'C-b'
# }}}

# {{{ Key bindings
if is_tmux_version ">= 2.4"; then
  # {{{ copy-selection without cancel
  tmux unbind -T copy-mode-vi Enter
  tmux bind -T copy-mode-vi Enter send-keys -X copy-selection

  # Text selection with mouse like general terminals
  tmux unbind -T copy-mode-vi MouseDragEnd1Pane
  # tmux bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection
  # }}}

  tmux unbind -T copy-mode-vi v
  tmux bind -T copy-mode-vi v send-keys -X begin-selection
  tmux unbind -T copy-mode-vi V
  tmux bind -T copy-mode-vi V send-keys -X select-line

  # make mouse wheel smoother
  tmux unbind -T copy-mode-vi WheelUpPane
  tmux bind -T copy-mode-vi WheelUpPane send-keys -X scroll-up
  tmux unbind -T copy-mode-vi WheelDownPane
  tmux bind -T copy-mode-vi WheelDownPane send-keys -X scroll-down
fi

if is_tmux_version ">= 3.0"; then
  tmux bind R "source ~/.config/tmux/tmux.conf; display 'tmux.conf is reloaded!'"
else
  tmux bind R "source ~/.tmux.conf; display '.tmux.conf is reloaded!'"
fi

# {{{ pane control
# when split window, the directory on new splitted window is same on original
# window.
tmux unbind "%"
tmux bind "%" split-window -h -c "#{pane_current_path}"
tmux unbind '"'
tmux bind '"' split-window -v -c "#{pane_current_path}"

# move pane with operation like vim
tmux bind k select-pane -U
tmux bind j select-pane -D
tmux bind h select-pane -L
tmux unbind l
tmux bind l select-pane -R

# Select pane using continuous Shift + JKHL typing.
tmux bind J "selectp -D; switchc -T prefix"
tmux bind K "selectp -U; switchc -T prefix"
tmux bind H "selectp -L; switchc -T prefix"
tmux unbind L
tmux bind L "selectp -R; switchc -T prefix"
# }}}

# {{{ other
tmux unbind q
tmux bind q display-panes -b -d 0

# Jump to previous prompt of pure
tmux bind B "copy-mode; send-keys -X search-backward '❯'; send-keys -X search-again"
# }}}

# {{{ commnad alias
# exec man by split window
tmux unbind m
tmux bind m command-prompt -p "<man vert>" "splitw 'man %%'"
tmux unbind M
tmux bind M command-prompt -p "<man horiz>" "splitw -h 'man %%'"

# exec tig
tmux bind g splitw -c "#{pane_current_path}" tig
tmux bind G splitw -h -c "#{pane_current_path}" tig
# }}}
# }}}

# {{{ Server options
if is_tmux_version ">= 2.4"; then
  tmux set -s command-alias[0] e="split-window -c '#{pane_current_path}'"
fi

case "${OSTYPE}" in
  linux* )
    tmux set -s default-terminal "tmux-256color"
    ;;
  darwin* )
    tmux set -s default-terminal "xterm-256color"
    ;;
esac
tmux set -s escape-time 0
tmux set -g history-file "${TMUX_DATA_HOME_PATH}/tmux_history"

# use true color in tmux
tmux set -sa terminal-overrides ",*256col*:Tc"
tmux set -sa terminal-overrides ",alacritty*:Tc"
# }}}

# {{{ Session options
tmux set -g default-command "${SHELL}"
tmux set -g display-time 0
tmux set -g history-limit 10000
tmux set -g mouse on
tmux set -g status-keys emacs

if ! is_ssh_connection; then
  tmux set -g status-position top
fi
# }}}

### {{{ Window options
tmux set -wg aggressive-resize on
tmux set -wg mode-keys vi
# }}}


tmux source -q "${TMUX_DATA_HOME_PATH}/tmux.local.conf"

# {{{ load tpm and plugins
# install `tpm` and plugins automatically when tmux is started
if [[ ! -d "${TMUX_PLUGIN_MANAGER_PATH}/tpm" ]]; then
  git clone 'https://github.com/tmux-plugins/tpm' "${TMUX_PLUGIN_MANAGER_PATH}/tpm" \
    && "${TMUX_PLUGIN_MANAGER_PATH}/tpm/bin/install_plugins"
fi

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
tmux run -b "${TMUX_PLUGIN_MANAGER_PATH}/tpm/tpm"
# }}}
