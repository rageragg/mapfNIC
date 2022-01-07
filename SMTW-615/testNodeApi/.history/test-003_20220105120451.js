const https = require('https')

function buscarCotizacionesCliente() {  

    const data = JSON.stringify({
        access_token: '',
        numeroCotizacion: '',
        usuario: 'cso_sa07@yahoo.com',
        tipUsuario: 'Perito',
        identificacion: '',
        placa: 'M168603'
    })

    const options = {
        hostname: 'mapfrenic.carrierhouse.us',
        port: 443,
        path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/buscarCotizacionesCliente',
        method: 'POST',
        headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
    }

    const req = https.request(options, res => {
        console.log(`Buscar Cotizaciones Clientes`);
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

buscarCotizacionesCliente();