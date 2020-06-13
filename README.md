# My Tmux Configures

Now, this configures are for tmux of master branch. So may occur errors on
release version which is installed with package manager.

## Setup

```sh
# Deploy into client
$ git clone https://github.com/a5ob7r/tmux-config.git
$ cd path/to/tmux-config
$ mkdir -p ~/.config
$ ln -sv "${PWD}" ~/.config/tmux

# Or

# Deploy into remote server
$ curl -L https://raw.githubusercontent.com/a5ob7r/tmux-config/master/etc/deploy.sh | bash
```
