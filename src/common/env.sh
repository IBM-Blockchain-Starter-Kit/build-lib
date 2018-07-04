: ${ROOTDIR:="."}

echo "ROOTDIR: " ${ROOTDIR}

export GO_VERSION="1.9.2"

# set location for go executables
export GOROOT=${ROOTDIR}/go
export PATH=${GOROOT}/bin:$PATH
export GOPATH=${ROOTDIR}

export HLF_VERSION="1.0.4"
export FABRIC_SRC_DIR=${ROOTDIR}/fabric-${HLF_VERSION}