export GO_VERSION="1.9.2"

# set location for go executables
export GOROOT=$(pwd)/go
export PATH=${GOROOT}/bin:$PATH
export GOPATH=$(pwd)

export HLF_VERSION="1.0.4"
export FABRIC_SRC_DIR=$(pwd)/fabric-${HLF_VERSION}