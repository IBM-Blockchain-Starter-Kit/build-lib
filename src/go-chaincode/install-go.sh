#!/bin/bash -x
echo "######## Begin install and configure Go ########"

echo "######## Extracting and decompressing Go version ${GO_VERSION} ########"
pwd 
curl -O https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz
tar -xvf go${GO_VERSION}.linux-amd64.tar.gz