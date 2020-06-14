#!/bin/bash
token=$1

curl -X POST -sL https://content.dropboxapi.com/2/files/download_zip \
    --header "Authorization: Bearer $token" \
    --header "Dropbox-API-Arg: {\"path\": \"/blog\"}" > output.zip

unzip output.zip
