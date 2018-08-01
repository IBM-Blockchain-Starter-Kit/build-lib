#!/usr/bin/env bash
ROOTDIR=${ROOTDIR:=$PWD}

export GO_VERSION=${GO_VERSION:="1.9.2"}

export NODE_VERSION=${NODE_VERSION:="10.7.0"}
export NVM_VERSION=${NVM_VERSION:="0.33.11"}


# set location for go executables
export GOROOT=${ROOTDIR}/go
export PATH=${GOROOT}/bin:$PATH
export GOPATH=${ROOTDIR}

export CONFIGPATH=${CONFIGPATH:="deploy_config.json"}
export CHAINCODEPATH=${CHAINCODEPATH:="chaincode"}

export HLF_VERSION=${HLF_VERSION:="1.1.2"}
export FABRIC_SRC_DIR=${ROOTDIR}/fabric-${HLF_VERSION}

export DEBUG=${DEBUG:=false}
