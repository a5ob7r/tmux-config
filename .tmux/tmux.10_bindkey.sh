source ~/.tmux/tmux.lib.sh

# {{{ prefix key
TMUX_PREFIX_KEY='C-q'
tmux set -g prefix $TMUX_PREFIX_KEY
tmux bind $TMUX_PREFIX_KEY send-prefix
tmux unbind 'C-b'
# }}}

# {{{ copy and paste
tmux bind Space copy-mode

# operation like vim
tmux bind p paste-buffer

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

# resize pane with intuitive key binding
tmux bind -r "<" resize-pane -L 1
tmux bind -r ">" resize-pane -R 1
tmux bind -r "-" resize-pane -D 1
tmux bind -r "+" resize-pane -U 1
# }}}

# {{{ other
tmux bind r source-file $HOME/.tmux.conf \; display ".tmux.conf is reloaded!"

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
