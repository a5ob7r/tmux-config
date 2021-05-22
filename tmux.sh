#!/usr/bin/env bash

# Functions {{{
# Set current tmux version on an environment variable to control tmux
# conficures per tmux version
is_tmux_version() {
  # conditional expression
  # ex. "= 1.9", "> 2.9"
  local -r cond_expr="$1"

  # current tmux version
  local -r tmux_version="$(tmux -V | sed 's/tmux \(next-\)*//g')"

  [[ "$(bc <<< "$tmux_version $cond_expr")" == 1 ]]
}

is_ssh_connection() {
  [[ -n "$SSH_CONNECTION" ]]
}
# }}}

readonly TMUX_DATA_HOME_PATH=~/.local/share/tmux
readonly TMUX_LOCAL_CONFIG="$TMUX_DATA_HOME_PATH/tmux.local.conf"

# Update SSH_AUTH_SOCK for re ssh-forwarding(ssh -A)
tmux set -g update-environment 'SSH_AUTH_SOCK'

# {{{ prefix key
readonly TMUX_PREFIX_KEY='C-q'
tmux set -g prefix "$TMUX_PREFIX_KEY"
tmux bind "$TMUX_PREFIX_KEY" send-prefix
tmux unbind 'C-b'
# }}}

# {{{ Key bindings
if is_tmux_version '>= 2.4'; then
  # {{{ copy-selection without cancel
  tmux unbind -T copy-mode-vi Enter
  tmux bind -T copy-mode-vi Enter send-keys -X copy-selection

  # Text selection with mouse like general terminals
  tmux unbind -T copy-mode-vi MouseDragEnd1Pane
  # tmux bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection
  # }}}

  # Vi like operations {{{
  tmux unbind -T copy-mode-vi v
  tmux bind -T copy-mode-vi v send-keys -X begin-selection
  tmux unbind -T copy-mode-vi V
  tmux bind -T copy-mode-vi V send-keys -X select-line
  # }}}

  # One mouse scroll unit is one line {{{
  tmux unbind -T copy-mode-vi WheelUpPane
  tmux bind -T copy-mode-vi WheelUpPane send-keys -X scroll-up
  tmux unbind -T copy-mode-vi WheelDownPane
  tmux bind -T copy-mode-vi WheelDownPane send-keys -X scroll-down
  # }}}
fi

# Reload config {{{
if is_tmux_version '>= 3.0'; then
  tmux bind R "source ~/.config/tmux/tmux.conf; display 'tmux.conf is reloaded!'"
else
  tmux bind R source ~/.tmux.conf\; display '.tmux.conf is reloaded!'
fi
# }}}

# {{{ pane control
# when split window, the directory on new splitted window is same on original
# window.
tmux unbind "%"
tmux bind "%" split-window -h -c "#{pane_current_path}"
tmux unbind '"'
tmux bind '"' split-window -v -c "#{pane_current_path}"

# Immediately jump to a window.
tmux bind -n M-0 select-window -t 0
tmux bind -n M-1 select-window -t 1
tmux bind -n M-2 select-window -t 2
tmux bind -n M-3 select-window -t 3
tmux bind -n M-4 select-window -t 4
tmux bind -n M-5 select-window -t 5
tmux bind -n M-6 select-window -t 6
tmux bind -n M-7 select-window -t 7
tmux bind -n M-8 select-window -t 8
tmux bind -n M-9 select-window -t 9

# move pane with operation like vim
tmux bind k select-pane -U
tmux bind j select-pane -D
tmux bind h select-pane -L
tmux unbind l
tmux bind l select-pane -R

tmux bind -Troot M-J selectp -D
tmux bind -Troot M-K selectp -U
tmux bind -Troot M-H selectp -L
tmux bind -Troot M-L selectp -R

# Select pane using continuous Shift + JKHL typing.
if is_tmux_version '> 2.1'; then
  tmux bind J 'selectp -D; switchc -T prefix'
  tmux bind K 'selectp -U; switchc -T prefix'
  tmux bind H 'selectp -L; switchc -T prefix'
  tmux unbind L
  tmux bind L 'selectp -R; switchc -T prefix'
fi
# }}}

# {{{ other
if is_tmux_version '> 2.1'; then
  tmux unbind q
  tmux bind q display-panes -b -d 0

  # Jump to previous prompt of pure
  tmux bind B "\
    copy-mode; \
    send-keys -X search-backward '${PURE_PROMPT_SYMBOL:-❯}'; \
    send-keys -X search-again \
    "
fi
# }}}

# {{{ commnad alias
# exec man by split window
tmux unbind m
tmux bind m command-prompt -p '<man vert>' "splitw 'man %%'"
tmux unbind M
tmux bind M command-prompt -p '<man horiz>' "splitw -h 'man %%'"

# exec tig
tmux bind g splitw -c '#{pane_current_path}' tig
tmux bind G splitw -h -c '#{pane_current_path}' tig
# }}}
# }}}

# {{{ Server options
if is_tmux_version '>= 2.4'; then
  tmux set -s command-alias[0] e="split-window -c '#{pane_current_path}'"
  tmux set -s command-alias[1] reindex='move-window -r'
fi

# Wanna set the value to 'tmux-256color'. But in many situation, it is more
# useful to set 'screen-256color'. For example, ssh connection with
# psuedo-terminal(-t option), vim color scheme with true color or vim buffer
# scrolling without background color erasing.
#
# NOTE: Consider per os type if set the value to 'tmux-256color'.
tmux set -s default-terminal 'screen-256color'

tmux set -s escape-time 0
tmux set -g history-file "$TMUX_DATA_HOME_PATH/tmux_history"

# use true color in tmux
tmux set -sa terminal-overrides ',*256col*:Tc'
tmux set -sa terminal-overrides ',alacritty*:Tc'
# }}}

# {{{ Session options
# Run interactive shell($SHELL -i, implicitly when no argument) instead of
# login shell($SHELL -l) on new panes. This aim is no load some configs for
# login shell. It is need to load the configs only when root login shell. The
# main configs are `export ENV=VAR` and starting daemons.
tmux set -g default-command "$SHELL"
if is_tmux_version '> 2.1'; then
  tmux set -g display-time 0
fi
tmux set -g history-limit 10000
tmux set -g mouse on
tmux set -g status-keys emacs

if ! is_ssh_connection; then
  tmux set -g status-position top
fi
# }}}

# {{{ Window options
tmux set -wg aggressive-resize on
tmux set -wg mode-keys vi
# }}}

# Others {{{
if is_tmux_version '>= 3.1'; then
  tmux source -q "$TMUX_LOCAL_CONFIG"
else
  [[ -f "$TMUX_LOCAL_CONFIG" ]] && tmux source "$TMUX_LOCAL_CONFIG"
fi
# }}}

# {{{ load tpm and plugins
# install `tpm` and plugins automatically when tmux is started
readonly TMUX_PLUGIN_MANAGER_PATH=~/.config/tmux/plugins

readonly TPM_DIR="$TMUX_PLUGIN_MANAGER_PATH/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  git clone 'https://github.com/tmux-plugins/tpm' "$TPM_DIR" \
    && "$TPM_DIR/bin/install_plugins"
fi

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
tmux run -b "$TPM_DIR/tpm"
# }}}
