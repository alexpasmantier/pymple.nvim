# TESTS_INIT=tests/minimal_init.lua
# TESTS_DIR=tests/

.PHONY: test lint docgen

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/ { minimal_init = './scripts/minimal_init.vim' }"

lint:
	luacheck lua/pymple

docgen:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "luafile ./scripts/gendocs.lua" -c 'qa'
