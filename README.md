# build-lib

Common scripts for use in Blockchain build pipelines

## Unit tests

This project is tested using Bats when making pull requests.

To run the tests locally, you will need to install the following modules: 

* [bats-core](https://github.com/bats-core/bats-core) 
* [bats-mock](https://github.com/jasonkarns/bats-mock)
* [jq](https://github.com/stedolan/jq)


```
brew install jq
cd build-lib
git clone --branch v1.0.2 --depth 1 https://github.com/bats-core/bats-core.git bats
git clone --branch v1.0.1 --depth 1 https://github.com/jasonkarns/bats-mock.git
```

Once the modules are installed run the following command from the `build-lib` directory:

```
cd build-lib
PATH="./bats/bin:$PATH" bats test/*
```