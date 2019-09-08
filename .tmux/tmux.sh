#!/usr/bin/env bash

# Set current tmux version on an environment variable to control tmux conficures
# per tmux version

for f in ~/.tmux/tmux.[0-9][0-9]*.sh; do
  source $f
done
