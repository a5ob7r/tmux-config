#!/usr/bin/env bash
# A deploy script to remote server

# Set useful shell options
set -Cueo pipefail

cd /tmp
curl -L https://api.github.com/repos/a5ob7r/tmux-config/tarball | tar zx
install -d ~/.config
mv a5ob7r-tmux-config-* ~/.config/tmux
cd ~/.config/tmux
grep -Ev 'tmux-plugins/tmux-battery|@TMUX_CZ' tmux.conf >> ~/.tmux.conf
