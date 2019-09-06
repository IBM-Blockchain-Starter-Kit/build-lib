#!/usr/bin/env bash
ROOTDIR=${ROOTDIR:=$(pwd)}

export DEBUG=${DEBUG:=false}

# set nvm and node expected versions
# export NODE_VERSION=${NODE_VERSION:="8.16.0"}
export NODE_VERSION="8.16.0"
# export NVM_VERSION="0.33.11"
export NVM_VERSION=${NVM_VERSION:="0.33.11"}

# set location for go executables
export GO_VERSION=${GO_VERSION:="1.11"}
export GOROOT=${ROOTDIR}/go
export PATH=${GOROOT}/bin:$PATH
export GOPATH=${ROOTDIR}
export PATH=${GOPATH}/bin:$PATH

# set location for python installation
export PYTHON_VERSION="2.7.15"
export PYTHONPATH=/opt/python/${PYTHON_VERSION}

# chaincode dir
export CHAINCODEPATH=$ROOTDIR/${CHAINCODEPATH:="/chaincode"}
export CONFIGPATH=${CONFIGPATH:="${CHAINCODEPATH}/deploy_config.json"}

# hlf dir
export HLF_VERSION=${HLF_VERSION:="1.4.1"}
export FABRIC_SRC_DIR=${ROOTDIR}/fabric-${HLF_VERSION}

# fabric-cli dir
export FABRIC_CLI_DIR=$ROOTDIR/${FABRIC_CLI_DIR:="/fabric-cli"}