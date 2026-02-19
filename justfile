export PATH := env_var("PATH") + ":" + justfile_directory() + "/bin"
set positional-arguments

@_help:
	just --list

[linux]
_setup_likelike:
	#!/bin/bash
	if ! &>/dev/null which likelike; then
		gh release download --repo chrisdickinson/likelike -p '*x64_linux*'
		<likelike*.tar.gz tar zxv -C bin
		mkdir -p ~/.local/share/likelike
	fi

[macos]
_setup_likelike:
	#!/bin/bash
	if ! &>/dev/null which likelike; then
		gh release download --repo chrisdickinson/likelike -p '*macos*'
		<likelike*.tar.gz tar zxv -C bin
		mkdir -p ~/.local/share/likelike
	fi

# Setup dependencies. Run automatically by other recipes.
_setup: _setup_likelike
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
