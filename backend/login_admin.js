const https = require('https');

const data = JSON.stringify({
  email: "athibantredars2005@gmail.com",
  password: "7678"
});

const options = {
  hostname: 'athiban-traders-app.onrender.com',
  port: 443,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = https.request(options, res => {
  let responseData = '';
  res.on('data', d => responseData += d);
  res.on('end', () => {
    console.log(`Login Status: ${res.statusCode}`);
    console.log(responseData);
    
    // Test fetch products using the token
    const token = JSON.parse(responseData).token;
    if (token) {
        console.log('Testing products endpoint...');
        const prodOptions = {
          hostname: 'athiban-traders-app.onrender.com',
          port: 443,
          path: '/api/products',
          method: 'GET',
          headers: {
            'Authorization': 'Bearer ' + token
          }
        };
        const prodReq = https.request(prodOptions, prodRes => {
          let pData = '';
          prodRes.on('data', d => pData += d);
          prodRes.on('end', () => {
            console.log(`Products Status: ${prodRes.statusCode}`);
            console.log(`Products returned: ${JSON.parse(pData).length}`);
          });
        });
        prodReq.end();
    }
  });
});

req.on('error', error => console.error(error));
req.write(data);
req.end();
