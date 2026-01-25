.PHONY: install uninstall test

PLUGIN_NAME := claude-session-summary
PLUGIN_DIR := $(HOME)/.claude/plugins/$(PLUGIN_NAME)

install:
	@echo "Installing $(PLUGIN_NAME)..."
	@mkdir -p $(PLUGIN_DIR)
	@cp -r .claude-plugin/* $(PLUGIN_DIR)/
	@mkdir -p $(PLUGIN_DIR)/scripts
	@cp scripts/*.zsh $(PLUGIN_DIR)/scripts/
	@chmod +x $(PLUGIN_DIR)/scripts/*.zsh
	@echo "Installed to $(PLUGIN_DIR)"
	@echo ""
	@echo "Add to ~/.tmux.conf for prefix + S viewing:"
	@echo 'bind-key S display-popup -w 80% -h 60% -E "glow ~/.local/share/claude-sessions/current.md 2>/dev/null || echo No summary yet."'

uninstall:
	@echo "Uninstalling $(PLUGIN_NAME)..."
	@rm -rf $(PLUGIN_DIR)
	@echo "Done"

test:
	@echo "Running session-summary.zsh..."
	@./scripts/session-summary.zsh
	@sleep 3
	@echo "Summary:"
	@cat ~/.local/share/claude-sessions/current.md 2>/dev/null || echo "No summary generated"
