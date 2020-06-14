#!/bin/bash

set -e

if [ -e bin/zola ]; then
  exit
fi

url=$(curl -s https://api.github.com/repos/getzola/zola/releases/latest | jq -r '.assets[].browser_download_url' | grep $(uname | tr '[:upper:]' '[:lower:]'))
echo -e '\x1b[33mDownloading zola from \x1b[33;4m'$url'\x1b[0m...'
curl -#L $url | tar xz -C bin
chmod +x bin/zola
bin/zola --version
