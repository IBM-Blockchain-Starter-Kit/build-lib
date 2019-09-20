// const a = {
//   "identities": [
//     { "role": { "name": "member", "mspId": "Org1MSP" }},
//     { "role": { "name": "member", "mspId": "Org2MSP" }}
//   ],
//   "policy": {
//     "1-of": [{ "signed-by": 0 }, { "signed-by": 1 }]
//   }
// };

// console.log(escape(JSON.stringify(a)));

const a = "{\"identities\":[{\"role\":{\"name\":\"member\",\"mspId\":\"Org1MSP\"}},{\"role\":{\"name\":\"member\",\"mspId\":\"Org2MSP\"}}],\"policy\":{\"1-of\":[{\"signed-by\":0},{\"signed-by\":1}]}}";
console.log(JSON.parse(a));