const http = require('https');

const data = JSON.stringify({
  name: "Athiban Admin",
  email: "athibantredars2005@gmail.com",
  password: "7678"
});

const options = {
  hostname: 'athiban-traders-app.onrender.com',
  port: 443,
  path: '/api/auth/register',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = http.request(options, res => {
  console.log(`statusCode: ${res.statusCode}`);
  res.on('data', d => process.stdout.write(d));
});

req.on('error', error => console.error(error));
req.write(data);
req.end();
