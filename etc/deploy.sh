#!/usr/bin/env bash
# A deploy script to remote server

# Set useful shell options
set -Cueo pipefail

curl -L https://api.github.com/repos/a5ob7r/tmux-config/tarball | tar zx
install -d ~/.config
mv a5ob7r-tmux-config-930727f ~/.config/tmux
cat tmux.plugins.conf tmux.conf | grep -Ev 'tmux-plugins/tmux-battery|@TMUX_CZ' >> ~/.tmux.conf
