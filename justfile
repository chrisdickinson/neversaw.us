export PATH := env_var("PATH") + ":" + justfile_directory() + "/bin"
set positional-arguments

@_help:
	just --list

# Setup dependencies. Run automatically by other recipes.
_setup:
	#!/bin/bash
	if ! &>/dev/null which zola; then
		url=$(curl -s https://api.github.com/repos/getzola/zola/releases/latest | jq -r '.assets[].browser_download_url' | grep $(uname | tr '[:upper:]' '[:lower:]'))
		echo -e '\x1b[33mDownloading zola from \x1b[33;4m'$url'\x1b[0m...'
		curl -sL $url | tar xz -C bin
		chmod +x bin/zola
		bin/zola --version
	fi

# Check that the site build works without outputting any files. (All options are forwarded to "zola check")
@check: _setup
	bin/zola

# Build the site.
@build *args: _setup
	zola build $@

# Serve the website. (All options are forwarded to "zola serve", including "--help".)
@serve:
	zola serve $@
