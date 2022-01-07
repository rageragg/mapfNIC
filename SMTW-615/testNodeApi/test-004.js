const https = require('https')

function informacionCotizacion() {  

    const data = JSON.stringify({
        access_token: '-224819472TKSZHHUD',
        numeroCotizacion: '2030100006012'
    })

    const options = {
        hostname: 'mapfrenic.carrierhouse.us',
        port: 443,
        path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/informacionCotizacion',
        method: 'POST',
        headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
    }

    const req = https.request(options, res => {
        console.log(`informacion Cotizacion`);
        console.log(`statusCode: ${res.statusCode}`);
        
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

informacionCotizacion();        