# build-lib

Common scripts for use in Blockchain build pipelines

## Unit tests

This project is tested using Bats when making pull requests.

To run the tests locally, install
[bats-core](https://github.com/bats-core/bats-core) and
[bats-mock](https://github.com/jasonkarns/bats-mock), then run the following
command from the uppermost directory:

```
PATH="./bats/bin:$PATH" bats test/*
```
