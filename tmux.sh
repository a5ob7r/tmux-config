#!/usr/bin/env bash
# Use pure bash functions as much as possible.
#
# TODO: Consider bash version to check whether or not specific features is
# enabled.
#
# Tested bash versions
# - 5.1.8(1)-release (x86_64-pc-linux-gnu)
# - 3.2.57(1)-release (x86_64-apple-darwin20)

# Functions {{{
has () {
  type "$1" &>/dev/null
}

# Return whether or not the argument format is natural number. Acceptable
# format is a string which is constructed from 0, 1, 2, .., 9 only. This
# doesn't accept null string.
# e.g.
# - 1
# - 300
is_nat () {
  [[ -n "$1" && "${1/[^0-9]/}" == "$1" ]]
}

# Return whether or not the argument format is a alphabet character.
# Acceptable format is which is constructed from single alphabet character.
# This doesn't accept null string.
# e.g.
# - a
# - Z
is_alphabet_char () {
  [[ "${#1}" == 1 && "${1/[a-zA-Z]/}" == '' ]]
}

#######################################
# Join lines with a delimiter.
# e.g.
# 3
# a
# 12
# bb -> 3.a.12.bb
# Global:
#   None
# Arguments:
#   Delim: A Deliimiter character to join lines.
# Return:
#   Joined string
#######################################
join_lines_with () {
  # shellcheck disable=2207
  local -ra lines=( $(</dev/stdin) )

  # First character of `IFS` is used as delimiter to join elements of array.
  local -r IFS="$1"

  # Join elements of array using `IFS`.
  echo "${lines[*]}"
}

#######################################
# Compare two value and return a string to show comparison result between two
# values. Acceptable value format is below.
# - natural number
#   - 3
#   - 111
# - single character
#   - a
#   - Z
# Return `UNDEFINED` if not acceptable format value is passed.
#
# Global:
#   None
# Arguments:
#   x: first value for comparison
#   y: second valud for comparison
# Return:
#   String: to show result between `x` and `y`
#     - EQ: equal
#     - GT: greater than
#     - LT: lesser than
#     - UNDEFINED: undefined
#######################################
cmp () {
  local -r x="$1"
  local -r y="$2"

  # e.g.
  # x: 3, y: 2
  (is_nat "$x" && is_nat "$y") \
    && if (( "$x" == "$y" )); then
      echo 'EQ'
    elif (( "$x" > "$y" )); then
      echo 'GT'
    elif (( "$x" < "$y" )); then
      echo 'LT'
    fi \
    && return 0

  # e.g.
  # x: a, y: 2
  (is_alphabet_char "$x" && is_nat "$y") \
    && echo 'GT' && return 0

  # e.g.
  # x: 2, y: a
  (is_nat "$x" && is_alphabet_char "$y") \
    && echo 'LT' && return 0

  # e.g.
  # x: a, y: b
  (is_alphabet_char "$x" && is_alphabet_char "$y") \
    && if [[ "$x" == "$y" ]]; then
      echo 'EQ'
    elif [[ "$x" > "$y" ]]; then
      echo 'GT'
    elif [[ "$x" < "$y" ]]; then
      echo 'LT'
    fi && return 0

  echo 'UNDEFINED'
}

# Return smaller value from two arguments.
min () {
  local -r x="$1"
  local -r y="$2"

  case $(cmp "$x" "$y") in
    GT )
      echo "$y"
      ;;
    * )
      echo "$x"
      ;;
  esac
}

# Convert version string to lines. Split version string per dot(.).
# e.g.
# 3.2 -> 3
#        2
version_to_lines () {
  local -r version="$(</dev/stdin)"
  local -r version_suffix_removed="${version%.}"

  while read -r -d '.' ver; do echo "$ver"; done <<<"${version_suffix_removed}."
}

#######################################
# Compare two version strings. Version string is like `1.2`, `3.3.3`.
# Global:
#   None
# Arguments:
#   x: First version string.
#   y: Second version string.
# Return:
#   Same to `cmp`
#######################################
cmp_versions() {
  # shellcheck disable=2207
  local -ra versions_x=( $(echo "$1" | version_to_lines) )
  # shellcheck disable=2207
  local -ra versions_y=( $(echo "$2" | version_to_lines) )

  local -r min_len="$(min "${#versions_x[*]}" "${#versions_y[*]}")"

  local compare='UNDEFINED'

  for (( i = 0; i < "$min_len"; i++ )); do
    local x="${versions_x[$i]}"
    local y="${versions_y[$i]}"

    compare="$(cmp "$x" "$y")"

    case "$compare" in
      EQ )
        ;;
      * )
        break
        ;;
    esac
  done

  echo "$compare"
}

# Return current tmux version. This aim is to remove extra prefixes.
tmux_version () {
  # Use cache if exists it.
  if [[ -n "$__TMUX_VERSION" ]]; then
    echo "$__TMUX_VERSION"
    return 0
  fi

  local version

  version="$(tmux -V)"
  version="${version/tmux /}"
  # Maybe HEAD's version output contains extra `next-` prefix.
  version="${version/next-/}"

  # Cache tmux version info to reduce overhead of invocation of tmux command.
  __TMUX_VERSION="$version"

  echo "$version"
}

# 1a -> 1
#       a
# 1 -> 1
split_tmux_version () {
  local -r version="$1"

  # e.g.
  # 3a -> x, y
  local -r x="${version/[a-z]*/}"
  local -r y="${version/*[0-9]/}"

  # Only output integer version if no alphabet part.
  if [[ "$version" == "$x" ]]; then
    echo "$x"
    return 0
  fi

  echo "$x"
  echo "$y"
}

# 3.3a -> 3
#         3
#         a
lines_tmux_version () {
  tmux_version | version_to_lines | while read -r ver; do
    split_tmux_version "$ver"
  done
}

# 3.3a -> 3.3.a
normalized_tmux_version () {
  lines_tmux_version | join_lines_with '.'
}

# Compare version string with current tmux version.
cmp_tmux_version () {
  cmp_versions "$(normalized_tmux_version)" "$1"
}

is_at_least () {
  case "$(cmp_tmux_version "$1")" in
    EQ | GT )
      return 0
      ;;
    * )
      return 1
      ;;
  esac
}

is_ssh_connection() {
  [[ -n "$SSH_CONNECTION" ]]
}
# }}}

# Variables {{{
readonly TMUX_DATA_HOME_PATH=~/.local/share/tmux
readonly TMUX_LOCAL_CONFIG="$TMUX_DATA_HOME_PATH/tmux.local.conf"
# }}}

# Prefix key {{{
readonly TMUX_PREFIX_KEY='M-q'
tmux set -g prefix "$TMUX_PREFIX_KEY"

# Send prefix key to tmux inside tmux by double typing prefix key.
tmux bind "$TMUX_PREFIX_KEY" send-prefix

# Unbind default prefix key.
tmux unbind 'C-b'
# }}}

# Key bindings {{{
if is_at_least '2.4'; then
  # copy-selection without cancel {{{
  tmux bind -T copy-mode-vi Enter send-keys -X copy-selection

  # Text selection with mouse like general terminals
  tmux unbind -T copy-mode-vi MouseDragEnd1Pane
  # tmux bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection
  # }}}

  # Vi like operations {{{
  tmux bind -T copy-mode-vi y send-keys -X copy-selection
  tmux bind -T copy-mode-vi Y 'send-keys -X begin-selection; send-keys -X end-of-line; send-keys -X copy-selection'
  tmux bind -T copy-mode-vi v send-keys -X begin-selection
  tmux bind -T copy-mode-vi V send-keys -X select-line
  tmux bind -T copy-mode-vi i send-keys -X cancel
  # }}}

  # One mouse scroll unit is one line {{{
  tmux bind -T copy-mode-vi WheelUpPane send-keys -X scroll-up
  tmux bind -T copy-mode-vi WheelDownPane send-keys -X scroll-down
  # }}}
fi

# Reload config {{{
if is_at_least '3.0'; then
  tmux bind R "source ~/.config/tmux/tmux.conf; display 'tmux.conf is reloaded!'"
else
  tmux bind R source ~/.tmux.conf\; display '.tmux.conf is reloaded!'
fi
# }}}

# {{{ pane control
# when split window, the directory on new splitted window is same on original
# window.
tmux bind "%" split-window -h -c "#{pane_current_path}"
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
tmux bind l select-pane -R

tmux bind -n M-J selectp -D
tmux bind -n M-K selectp -U
tmux bind -n M-H selectp -L
tmux bind -n M-L selectp -R

tmux bind -n M-% split-window -h -c "#{pane_current_path}"
tmux bind -n 'M-"' split-window -v -c "#{pane_current_path}"
tmux bind -n M-c new-window
tmux bind -n M-j select-pane -D
tmux bind -n M-k select-pane -U
tmux bind -n M-h select-pane -L
tmux bind -n M-l select-pane -R
tmux bind -n M-z resize-pane -Z
tmux bind -n M-J resize-pane -D
tmux bind -n M-K resize-pane -U
tmux bind -n M-H resize-pane -L
tmux bind -n M-L resize-pane -R
tmux bind -n 'M-[' copy-mode

# Select pane using continuous Shift + JKHL typing.
if is_at_least '2.2'; then
  tmux bind J 'selectp -D; switchc -T prefix'
  tmux bind K 'selectp -U; switchc -T prefix'
  tmux bind H 'selectp -L; switchc -T prefix'
  tmux bind L 'selectp -R; switchc -T prefix'
fi
# }}}

# {{{ other
if is_at_least '2.2'; then
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
tmux bind m command-prompt -p '<man vert>' "splitw 'man %%'"
tmux bind M command-prompt -p '<man horiz>' "splitw -h 'man %%'"

# exec tig
tmux bind g splitw -c '#{pane_current_path}' tig
tmux bind G splitw -h -c '#{pane_current_path}' tig
# }}}
# }}}

# Server options {{{
if is_at_least '2.4'; then
  tmux set -sa command-alias e="split-window -c '#{pane_current_path}'"
  tmux set -sa command-alias reindex='move-window -r'
fi

# Wanna set the value to 'tmux-256color'. But in many situation, it is more
# useful to set 'screen-256color'. For example, ssh connection with
# psuedo-terminal(-t option), vim color scheme with true color or vim buffer
# scrolling without background color erasing.
#
# NOTE: Consider per os type if set the value to 'tmux-256color'.
tmux set -s default-terminal 'screen-256color'

tmux set -s escape-time 0
if is_at_least '2.1'; then
  tmux set -g history-file "$TMUX_DATA_HOME_PATH/tmux_history"
fi

# Enable extra terminal features.
# - RGB/Tc: Direct(true or RGB) color.
if is_at_least '3.2'; then
  # It is added on c91b4b2e142b5b3fc9ca88afec6bfa9b2711e01b.

  # Matchs to st-256color, xterm-256colour, screen-256color and so on.
  tmux set -sa terminal-features '*256col*:RGB'

  # Matches to alacritty or alacritty-direct.
  tmux set -sa terminal-features 'alacritty*:RGB'
else
  # For backwards compatibility.
  tmux set -sa terminal-overrides ',*256col*:Tc'
  tmux set -sa terminal-overrides ',alacritty*:Tc'
fi
# }}}

# Session options {{{
# Run interactive shell($SHELL -i, implicitly when no argument) instead of
# login shell($SHELL -l) on new panes. This aim is no load some configs for
# login shell. It is need to load the configs only when root login shell. The
# main configs are `export ENV=VAR` and starting daemons.
tmux set -g default-command "$SHELL"
tmux set -g display-time 0
tmux set -g history-limit 10000
if is_at_least '2.1'; then
  # Enabled since bf635e7741f7b881f67ec7e4a5caa02f7ff3d786
  tmux set -g mouse on
else
  tmux set -g mouse-resize-pane on
  tmux set -g mouse-select-pane on
  tmux set -g mouse-select-window on
fi
tmux set -g status-keys emacs

if ! is_ssh_connection; then
  tmux set -g status-position top
fi

# Update SSH_AUTH_SOCK for re ssh-forwarding(ssh -A)
tmux set -g update-environment 'SSH_AUTH_SOCK'
# }}}

# Window options {{{
if ! is_at_least '2.1'; then
  tmux set -g mode-mouse on
fi
tmux set -wg aggressive-resize on
tmux set -wg mode-keys vi
# }}}

# Others {{{
if is_at_least '3.1'; then
  tmux source -q "$TMUX_LOCAL_CONFIG"
else
  [[ -f "$TMUX_LOCAL_CONFIG" ]] && tmux source "$TMUX_LOCAL_CONFIG"
fi
# }}}

# Load tpm and plugins {{{
# install `tpm` and plugins automatically when tmux is started
readonly TMUX_PLUGIN_MANAGER_PATH=~/.config/tmux/plugins

readonly TPM_DIR="$TMUX_PLUGIN_MANAGER_PATH/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  has git \
    && git clone 'https://github.com/tmux-plugins/tpm' "$TPM_DIR" \
    && "$TPM_DIR/bin/install_plugins"
fi

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
tmux run -b "$TPM_DIR/tpm"
# }}}

# vim: set foldmethod=marker :
