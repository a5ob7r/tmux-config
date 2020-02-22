CONFIG_DIR = ~/.config
TMUX_CONFIG_DIR = $(CONFIG_DIR)/tmux

setup:
	@if [ ! -d $(CONFIG_DIR) ]; then mkdir -v $(CONFIG_DIR); fi

link:
	@ln -sfv $(CURDIR) $(TMUX_CONFIG_DIR)

unlink:
	@unlink $(TMUX_CONFIG_DIR)
