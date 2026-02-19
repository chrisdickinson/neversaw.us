export PATH := env_var("PATH") + ":" + justfile_directory() + "/bin"
set positional-arguments

@_help:
	just --list


# Setup dependencies. Run automatically by other recipes.
_setup:
	#!/bin/bash
	set -eou pipefail
	mkdir -p bin
	arch=$(uname -m | sed -e 's/arm64/aarch64/g')
	plat=$(uname | tr '[:upper:]' '[:lower:]')
	if ! &>/dev/null which zola; then
		url=($(curl -s https://api.github.com/repos/getzola/zola/releases/latest | jq -r '.assets[].browser_download_url' | grep $plat | grep $arch))
		echo -e '\x1b[33mDownloading zola from \x1b[33;4m'${url[0]}'\x1b[0m...'
		curl -sL ${url[0]} | tar xz -C ./bin
		chmod +x bin/zola
		bin/zola --version
	fi
	if ! &>/dev/null which likelike; then
		gh release download --repo chrisdickinson/likelike -p '*'"$plat"'*'
		<likelike*.tar.gz tar zxv -C ./bin
		rm likelike*.tar.gz
		mkdir -p ~/.local/share/likelike
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
