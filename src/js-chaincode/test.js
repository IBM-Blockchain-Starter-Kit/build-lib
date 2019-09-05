const fs = require('fs');

// var package_json = JSON.parse(fs.readFileSync('/Users/abisarvepalli/Developer/ucs-chaincode/package.json').toString());
var package_json = JSON.parse(fs.readFileSync('package.json').toString());
if (package_json.nyc) {
    if (package_json.nyc.exclude) {
        package_json.nyc.exclude.push_back(process.env.FABRIC_CLI_DIR)
    } 
    else {
        package_json.nyc.exclude = [process.env.FABRIC_CLI_DIR];
    }

    fs.writeFileSync('package.json', JSON.stringify(package_json));
}