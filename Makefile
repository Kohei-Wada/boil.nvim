.PHONY: test lint format

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory tests { minimal_init = './scripts/minimal_init.vim' }"

# Lint code with luacheck
lint:
	luacheck lua/

# Format code with stylua
format:
	stylua lua/
