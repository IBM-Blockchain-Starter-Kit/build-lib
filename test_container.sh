rm -rf TEMP

save="$1"

mkdir TEMP

# Copy scripts
mkdir TEMP/scripts
cp -a src/* TEMP/scripts

# TODO: Make work with composer scaffolding
# Copy scaffolding
mkdir TEMP/src
CONTRACT_URL="https://raw.githubusercontent.com/IBM-Blockchain-Starter-Kit/chaincode-bootstrap/master/src/chaincode/contract.go"
(curl -sSL ${CONTRACT_URL}) > TEMP/src/contract.go

# Copy test scripts
mkdir TEMP/test
cp -a test/* TEMP/test

# TODO: Run without being in context of TEMP and copying in test scripts
# Run test scripts
cd TEMP
bats -t test/*
test_results=$?
cd ..

# Remove scripts
rm -rf TEMP

exit ${test_results}
