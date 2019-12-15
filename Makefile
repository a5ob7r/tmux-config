CONFIG_DIR = ~/.config
TMUX_CONFIG_DIR = $(CONFIG_DIR)/tmux
TMUX_CONF_PATH = ~/.tmux.conf

setup:
	@if [ ! -d $(CONFIG_DIR) ]; then mkdir -v $(CONFIG_DIR); fi

link:
	@ln -sfv $(CURDIR) $(TMUX_CONFIG_DIR)
	@ln -sfv $(CURDIR)/tmux.plugins.conf $(TMUX_CONF_PATH)

unlink:
	@unlink $(TMUX_CONFIG_DIR)
	@unlink $(TMUX_CONF_PATH)
