mkdir TEMP

# Copy scripts
mkdir TEMP/scripts
cp -a src/* TEMP/scripts

# Copy scaffolding
mkdir TEMP/src
CONTRACT_URL="https://raw.githubusercontent.com/IBM-Blockchain-Starter-Kit/chaincode-bootstrap/master/src/chaincode/"
(curl ${CONTRACT_URL}) > TEMP/src/contract.go

# Copy test scripts
mkdir TEMP/test
cp -a test/* TEMP/test

# Run test scripts
cd TEMP
bats test/*
cd ..

# Remove scripts
rm -rf TEMP
