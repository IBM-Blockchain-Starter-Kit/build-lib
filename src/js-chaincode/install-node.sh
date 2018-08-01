#!/usr/bin/env bash

echo "######## Begin install and configure Node ########"
export NVM_DIR=/home/pipeline/nvm

mkdir -p $NVM_DIR

echo "######## Installing Node.js version ${NODE_VERSION} using nvm ${NVM_VERSION} ########"
npm config delete prefix \
  && curl https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | sh \
  && . $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default \
  && node -v \
  && npm -v

