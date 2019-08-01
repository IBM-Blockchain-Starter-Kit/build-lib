#!/usr/bin/env bash
ROOTDIR=${ROOTDIR:=$PWD}

export GO_VERSION=${GO_VERSION:="1.11"}

# export NODE_VERSION=${NODE_VERSION:="8.9.0"}
export NODE_VERSION="8.16.0"
export NVM_VERSION=${NVM_VERSION:="0.33.11"}
# export NVM_VERSION="0.33.11"
export PYTHON_VERSION="2.7.15"

export DEBUG=${DEBUG:=false}

# set location for go executables
export GOROOT=${ROOTDIR}/go
export PATH=${GOROOT}/bin:$PATH
export GOPATH=${ROOTDIR}
export PATH=${GOPATH}/bin:$PATH

# chaincode dir
export CONFIGPATH=${CONFIGPATH:="$(pwd)/deploy_config.json"}
export CHAINCODEPATH=${CHAINCODEPATH:="chaincode"}

# hfl dir
export HLF_VERSION=${HLF_VERSION:="1.4.1"}
export FABRIC_SRC_DIR=${ROOTDIR}/fabric-${HLF_VERSION}

# fabric-cli dir
export FABRIC_CLI_DIR=${ROOTDIR}/${FABRIC_CLI_DIR}