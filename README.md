# build-lib

This repository contains common scripts for use in Blockchain build pipelines.

## GO vendoring
If your GO chanincode requires vendoring of GO packages, you should include a `.govendor_packages` file inside each chaincode component folder. At the moment, you should only specify in the `.govendor_packages` file libraries that are part of the Fabric binaries. Specifying libraries that are not in the Fabric binaries will more than likely result in compilation errors during the build phase of the toolchain (we plan to address this limitation soon).

The `.govendor_packages` file should contain one line for every GO package that should be vendored in. The syntax for specifying a GO dependency in the `.govendor_packages` file simply follows the format required by the [govendor](https://github.com/kardianos/govendor) tool.

```
github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1
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
cp binstub stub.bash <<absolute path to the build-lib repository>/bats-mock
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
