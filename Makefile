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
	@# Register plugin if not already registered
	@if ! grep -q '"$(PLUGIN_NAME)@local"' $(HOME)/.claude/plugins/installed_plugins.json 2>/dev/null; then \
		jq '.plugins["$(PLUGIN_NAME)@local"] = [{"scope": "user", "installPath": "$(PLUGIN_DIR)", "version": "1.0.0", "installedAt": "'$$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'", "lastUpdated": "'$$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'"}]' \
			$(HOME)/.claude/plugins/installed_plugins.json > /tmp/plugins.json && \
		mv /tmp/plugins.json $(HOME)/.claude/plugins/installed_plugins.json; \
		echo "Registered plugin in installed_plugins.json"; \
	fi
	@echo "Installed to $(PLUGIN_DIR)"
	@echo ""
	@echo "IMPORTANT: Restart Claude to activate the plugin!"
	@echo ""
	@echo "Add to ~/.tmux.conf for prefix + S viewing:"
	@echo 'bind-key S display-popup -w 80% -h 60% -E "glow -p ~/.local/share/claude-sessions/current.md 2>/dev/null || { echo No summary yet.; read; }"'

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
