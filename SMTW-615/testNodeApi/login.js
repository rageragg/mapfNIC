const https = require('https')


function login() {  

    const data = JSON.stringify({
        username: 'cso_sa07@yahoo.com', 
        password: '542823a4e9acbac64ec21659c5a7c415', 
        grant_type: 'password' 
    })

    const options = {
    hostname: 'mapfrenic.carrierhouse.us',
    port: 443,
    path: '/PWA-Autoinspecciones/token',
    method: 'POST',
    headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length
        }
    }

    const req = https.request(options, res => {
        console.log(`Login`);
        console.log(`statusCode: ${res.statusCode}`)
        
        res.on( 'data', d => {
            process.stdout.write(d)
        });

    })

    req.on('error', error => {
        console.error(error);
    });

    req.write(data);
    req.end();
}

login();