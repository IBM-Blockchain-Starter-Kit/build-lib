# build-lib

This repository contains common scripts for use in Blockchain build pipelines. Currently there's a mix of fabric-apis to call, specifically a 
fabric-cli javascript version that is fetch from https://github.com/IBM-Blockchain-Starter-Kit/fabric-cli and use of peer cli from hyperledger/fabric
releases.

## Project Structure
The entry point is src/router.sh

There are scripts for 2 types of chaincode, go and js and within each folder (go-chaincode and js-chaincode) has a file and they represent
a stage of a pipeline.

## Environment Setups
Each stage will call common/env.sh to set up the environment.

Any ENV that is not defined Required are optional

- DEBUG           - default to false, set this to true for verbose
- NODE_VERSION    - Node version to install the bin. Must match a node version from repository.
- NVM_VERSION     - NVM version to use and install. Must match a nvm official version.
- GO_VERSION      - defaults to 1.12, much match a go version to install if using golang chaincode.
- GOROOT          - defaults to HOME/go or set your GOROOT
- PATH            - Set your path or defaults to OS PATH env
- CC_REPO_DIR     - Location of your chaincode absolute path. Defaults to CWD/chaincode-repo. CWD is directory where router.sh is called
- CONFIGPATH      - *Required*: deploy_config.json path. Refer to deploy_config.json below for more configuration
- CHAINCODEPATH   - *Required*: for golang only and if you are using build stage. This is required to place chaincode in go/src and prior to go modules
- HLF_VERSION     - Hyperledger fabric version, must be correct version as fetching binaries from repository is executed with this env.
- ENABLE_PEER_CLI - Defaults to false. Enable the use of fabric peer cli instead of fabric-cli javascript for fabric api, must set to *true* if you want to use peer cli. Prior to this, a fabric-cli js was used. Check prepare.sh for details.
- PEER_CLI_V1               - set to true if required for fabric v1.x to use hyperledger fabric peer cli. Note fabric v1.x defaults to using fabric-cli js in some scripts.
- ORDERERS_LIST_JSON_STRING - *Required*: A json string object or array of orderer's node information. This string will get parsed by `jq` and information extracted. See more below. Can be retrieved from IBP export orderers
- ADMIN_IDENTITY_STRING     - *Required*: A json string object of admin identity. Refer below for required fields and examples. Can be retrieved from IBP export Identities. Will require extra step if `ca` property is missing.
- CONNECTION_PROFILE_STRING - *Required*: A json string object of the connection profile to use for fabric api execution. env.sh builds peer cli 
strings for --peerAddresses and --tlsRootCertFiles flags in the order of peers array in cp
- CC_NAME_OVERRIDE          - Set Chaincode name override, or else default to deploy_config.json settings
- CC_VERSION_OVERRIDE       - Override for chaincode version, or else default to latest if not set in deploy_config.json
- CC_SEQUENCE_OVERRIDE      - Override for seq number for fabric v2.x . If not set, code will handle incrementation in js-chaincode/package.sh. Need to complete for golang
- CC_PACKAGE_LOCATION       - chaincode package location. TODO fabric v2 js packages tgz and fabric v1 go packages tgz but needs to account for cds
- INSTALL_OVERRIDE_SKIP     - default to false, set to true if install stage needs to be skipped. This is needed incase pipeline gets out of sync with installed cc.
- SIGN_POLICY               - fabric v2.x signature policy for chaincode cmds.
- ENDORSEMENT_POLICY        - fabric v1.x endorsement policy for chaincode cmds
- INIT_ARGS                 - init args constructure for fabric v1.x peer cli cmd, defaults to '{}'. Example {\"Args\":[\"initMarble\",\"marble1\"]}"
- CC_INDEX                  - Use to index into deploy_config.json chaincode index. If multiple chaincode are set, CC_INDEX will set context of chaincode operate on.

## deploy_config.json

This json is used to extract chaincode information such as chaincode name, versions, paths, and channels.

*Although chaincode is an array(for backwards compatible), do not have more than 1 chaincode object when using V2*

```json
{
  "org": {
    "_COMMENT": "This is a config for pipeline script to deploy the chaincode.",
    "chaincode": [
      {
        "name": "somecc",
        "path": "path/to/cc",
        "channel": "channel",
        "install": true,
        "instantiate": true,
        "init_args": "\"{\"arg1\":\"000000\",}\"}",
        "init_fn": "init"
      }
    ]
  }
}

```
INFO:

- org - anything can be placed here that satisfy regex [a-zA-Z]
- chaincode - Array of chaincode, a repo may have multiple chaincode
- name - name of chaincode, script will use this to build CC_NAME env
- path - path to chaincode entry point or building directory
- channel - channel to install the chaincode, this builds into CHANEL_NAME env for the script
- install - fabric-cli js uses this
- instantiate - fabric-cli js uses this
- init_args - fabric-cli js uses this
- init_fcn - fabric-cli js uses this

## ORDERERS_LIST_JSON_STRING

Sample JSON, ORDERERS_LIST_JSON_STRING *must be a json string*. Script will use this array of orderers as a retry round-robin in the
event an orderer is down or not reachable.
```json
[
    {
        "api_url": "grpcs://orderer-node:7050",
        "pem": "LS0tLS1CRU..."
    }
]
```

INFO:
- api_url - grpcs url of orderer node
- pem - base64 encoded tls cert for orderer node

## ADMIN_IDENTITY_STRING

Admin identity string used to make fabric api calls. This ENV must be a json string.

```json
{
    "name": "admin",
    "ca": "LS0tLS1CRUd...",
    "private_key": "LS0tLS...",
    "cert": "LS0tLS..."
}
```

INFO:

- name - name of identity
- ca - base64 encoded rootcert of the msp
- private_key - base64 encoded private key of the identity
- cert - base64 encoded cert of the identity


## Example Usage
General idea is to override some envs values you need before calling route.sh or allow all default settings to fall through

Examples, assuming that build-lib is cloned into $HOME dir and $HOME is the root dir of the chaincode proj. Examples below are showing 
different context settings and not necessarily valid in a pipeline

- **Build stage**
```bash
!#/bin/bash
CONFIGPATH=$HOME/deploy_config.json
source build-lib/src/router.sh build js
```

- **Package Stage**
```bash
!#/bin/bash
CONFIGPATH=$HOME/deploy_config.json
CC_VERSION_OVERRIDE=$GIT_COMMIT
source build-lib/src/router.sh package js
```

- **Install Stage**
```bash
CC_INDEX=1
INSTALL_OVERRIDE_SKIP=false
# Change identity context, to install. This Install Stage can be daisy chained for multiple orgs install during development
ADMIN_IDENTITY_STRING=$ORG2_ADMIN_STRING
CONNECTION_PROFILE_STRING=$ORG2_CP
CC_PACKAGE_LOCATION=$HOME/somepackage@v1.0.cds

source build-lib/src/router.sh install go

```

- **Deploy Stage**

Note! When setting Deploy's stage context, CONNECTION_PROFILE_STRING must contain the CP of the first org's Install/Approve stage CP. If you want to deploy to all or some org(s), you must add the peer information in the CP's organizations.[yourmsp].peers and peers definition. Order is important, make sure [yourmsp] org peers are first in both of these properties.
```bash
#!/bin/bash
## Override SEQ number
#export CC_SEQUENCE_OVERRIDE=2
source build.properties

export CC_VERSION_OVERRIDE=$GIT_COMMIT_HASH
set -x
source "${SCRIPT_DIR}/router.sh" deploy_v2 "${PLATFORM}"
```

## Unit tests

Make sure you have installed [jq](https://stedolan.github.io/jq/download/) before attempting to run the test cases on your local system.

This project is tested using Bats when making pull requests.

To run the tests locally, install [bats-core](https://github.com/bats-core/bats-core) and [bats-mock](https://github.com/jasonkarns/bats-mock). Here are a few tips on installing these two libraries so you don't go into a rabbit hole when attempting to run the test cases.

### bats-core

You should [install](https://github.com/bats-core/bats-core#installing-bats-from-source) bats-core from source. After you have cloned `bats-core` into the directory of your choosing, navigate to that folder and run the `./install.sh` script by passing the absolute path to the folder where this repository (i.e. `build-lib`) was cloned into your local system and appending `bats` folder to that path as shown below:

```
./install.sh <absolute path to the build-lib repository>/bats
```

Executing the `install.sh` script should result in the creation of a `bats` folder under the `build-lib` repository; this `bats` folder contains the `bats-core` files.

### bats-mock
To install `bats-mock`, first create an empty folder named `bats-mock` under the `build-lib` repository. Then clone the [bats-mock](https://github.com/jasonkarns/bats-mock) repository into the directory of your choosing; navigate to that folder, copy the `binstub` and `stub.bash` files into the `bats-mock` you created under the `build-lib` repository.
```
mkdir <absolute path to the build-lib repository>/bats-mock
cp binstub stub.bash <absolute path to the build-lib repository>/bats-mock
```


### Issues with running bats command
If running on a Mac OS machine, you may have to use a package installer (i.e. Homebrew) to install the greadlink binary.
```
brew install coreutils
```

### Running test cases
Once you have installed `bats-core` and `bats-mock` as described the sections above, you can then run the following command from the root directory of this repository:

```
PATH="./bats/bin:$PATH" bats test/*
```
