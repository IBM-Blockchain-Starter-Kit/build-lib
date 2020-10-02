#!/usr/bin/env bash
ROOTDIR=${ROOTDIR:=$(pwd)}

export DEBUG=${DEBUG:=false}

# set nvm and node expected versions
NODE_VERSION=${NODE_VERSION:-"8.16.2"}
export NODE_VERSION=${NODE_VERSION}
# export NVM_VERSION="0.33.11"
export NVM_VERSION=${NVM_VERSION:="0.35.1"}

# set location for go executables
export GO_VERSION=${GO_VERSION:="1.12"}
export GOROOT=${ROOTDIR}/go
export PATH=${GOROOT}/bin:$PATH
export GOPATH=${ROOTDIR}
export PATH=${GOPATH}/bin:$PATH

# set location for python installation
export PYTHON_VERSION="2.7.15"
export PYTHONPATH=/opt/python/${PYTHON_VERSION}

# chaincode dir
export CC_REPO_DIR=${CC_REPO_DIR:-"${ROOTDIR}/chaincode-repo"}
export CONFIGPATH=${CONFIGPATH:-"${CC_REPO_DIR}/deploy_config.json"}
# - only for golang chaincode projects
export CHAINCODEPATH=${CHAINCODEPATH:-"$CC_REPO_DIR/chaincode"}

# hlf dir
export HLF_VERSION=${HLF_VERSION:="1.4.4"}
export FABRIC_SRC_DIR=${ROOTDIR}/fabric-${HLF_VERSION}

# fabric-cli dir
export FABRIC_CLI_DIR=$ROOTDIR/${FABRIC_CLI_DIR:="/fabric-cli"}