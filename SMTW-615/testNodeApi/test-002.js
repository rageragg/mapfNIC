const https = require('https')

function envioRespuestas() {  

    const data = JSON.stringify({
        access_token: '-705798175IKKRKZIV',
        usuario: '',
        numeroCotizacion: '2130100036987',
        resultado: 'APROBADO',
        comentarios: 'PRUEBAS MASIVAS',
        controlesTecnicos: [ { control: 'control 1' }, { control: 'control 2' } ]
    })

    const options = {
        hostname: 'mapfrenic.carrierhouse.us',
        port: 443,
        path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/envioRespuesta',
        method: 'POST',
        headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
    }

    const req = https.request(options, res => {
        console.log(`Envio de Respuestas`);
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

function documentacion() {  

    const data = JSON.stringify({
        access_token: '-705798175IKKRKZIV',
        documentos: [
            {
                usuario: 'cso_sa07@yahoo.com',
                numeroCotizacion: '2130100036987',
                tipoDocumento: 'Licencia',
                byteFoto: '1209903901293023'
            },
            {
                usuario: 'cso_sa07@yahoo.com',
                numeroCotizacion: '2130100036987',
                tipoDocumento: 'Documentos del Vehiculo',
                byteFoto: '123298671263763'
            }
        ]
    })

    const options = {
        hostname: 'mapfrenic.carrierhouse.us',
        port: 443,
        path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/documentacion',
        method: 'POST',
        headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
    }

    const req = https.request(options, res => {
        console.log(`Documentacion`);
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

function accesoriosVehiculo() {  

    const data = JSON.stringify({
        access_token: '-705798175IKKRKZIV',
        detalles: [
            {
                numeroCotizacion: '2130100036987',
                marca: 'JBC',
                referencia: 'Radio Desmontable',
                valor: 123,
                byteFoto: '1209903901293023'
            },
            {
                numeroCotizacion: '2130100036987',
                marca: 'SONY',
                referencia: 'Planta de Sonido',
                valor: 432,
                byteFoto: '1209903901293023'
            }
        ]
    })

    const options = {
        hostname: 'mapfrenic.carrierhouse.us',
        port: 443,
        path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/documentacion',
        method: 'POST',
        headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
    }

    const req = https.request(options, res => {
        console.log(`Accesorios de Vehiculo`);
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

function danosVehiculo() {  

    const data = JSON.stringify({
        access_token: '-705798175IKKRKZIV',
        detalles: [
            {
                pieza: 'Faro delantero Izquierdo',
                numeroCotizacion: '2130100036987',
                nivelDano: 'Leve',
                valor: 129,
                byteFoto: '1209903901293023'
            },
            {
                pieza: 'Vidrio lateral Tras. Izquierdo',
                numeroCotizacion: '2130100036987',
                nivelDano: 'Grave',
                valor: 43,
                byteFoto: '1209903901293023'
            }
        ]
    })

    const options = {
        hostname: 'mapfrenic.carrierhouse.us',
        port: 443,
        path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/danosVehiculo',
        method: 'POST',
        headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
    }

    const req = https.request(options, res => {
        console.log(`Danos de Vehiculo`);
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

function fotosVehiculo() {  

    const data = JSON.stringify({
        access_token: '-705798175IKKRKZIV',
        fotos: [
            {
                numeroCotizacion: '2130100036987',
                tipoFoto: 'Lateral Izquierdo',
                byteFoto: '1209903901293023'
            },
            {
                numeroCotizacion: '2130100036987',
                tipoFoto: 'Tracero',
                byteFoto: '1209903901293023'
            }
        ]
    })

    const options = {
        hostname: 'mapfrenic.carrierhouse.us',
        port: 443,
        path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/fotosVehiculo',
        method: 'POST',
        headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
    }

    const req = https.request(options, res => {
        console.log(`Fotos de Vehiculo`);
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

envioRespuestas();
documentacion();
accesoriosVehiculo();
danosVehiculo();
fotosVehiculo();
