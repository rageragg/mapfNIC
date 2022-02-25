const https = require('https')


function listaColores() {  

    const data = JSON.stringify({
    access_token: '-663480928CUXYMXMZ'
    })

    const options = {
    hostname: 'mapfrenic.carrierhouse.us',
    port: 443,
    path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/listaColores',
    method: 'POST',
    headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length
        }
    }

    const req = https.request(options, res => {
        console.log(`Lista Colores`);
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

function listaUsos() {  

    const data = JSON.stringify({
    access_token: '-663480928CUXYMXMZ'
    })

    const options = {
    hostname: 'mapfrenic.carrierhouse.us',
    port: 443,
    path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/listaUsos',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
    }
    }

    const req = https.request(options, res => {
        console.log(`Lista Usos`);
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

function listaLineas() {  

    const data = JSON.stringify({
        access_token: '-663480928CUXYMXMZ',
        codigo: '100'
    })

    const options = {
    hostname: 'mapfrenic.carrierhouse.us',
    port: 443,
    path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/listaLineas',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
    }
    }

    const req = https.request(options, res => {
        console.log(`Lista Lineas`);
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

function listaMarcas() {  

    const data = JSON.stringify({
        access_token: '-663480928CUXYMXMZ'
    })

    const options = {
    hostname: 'mapfrenic.carrierhouse.us',
    port: 443,
    path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/listaMarcas',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
    }
    }

    const req = https.request(options, res => {
        console.log(`Lista Marcas`);
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

function listaMunicipios() {  

    const data = JSON.stringify({
        access_token: '-663480928CUXYMXMZ',
        codigo: 15
    })

    const options = {
    hostname: 'mapfrenic.carrierhouse.us',
    port: 443,
    path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/listaMunicipios',
    method: 'POST',
    headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length
        }
    }

    const req = https.request(options, res => {
        console.log(`Lista Municipios`);
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

function listaDepartamentos() {  

    const data = JSON.stringify({
        access_token: '-663480928CUXYMXMZ',
        codigo: 15
    })

    const options = {
    hostname: 'mapfrenic.carrierhouse.us',
    port: 443,
    path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/listaDepartamentos',
    method: 'POST',
    headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length
        }
    }

    const req = https.request(options, res => {
        console.log(`lista Departamentos`);
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

function listaPiezas() {  

    const data = JSON.stringify({
        access_token: '-663480928CUXYMXMZ',
        codigo: 15
    })

    const options = {
    hostname: 'mapfrenic.carrierhouse.us',
    port: 443,
    path: '/PWA-Autoinspecciones/api/apiexterno/autoinsp/listaPiezas',
    method: 'POST',
    headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length
        }
    }

    const req = https.request(options, res => {
        console.log(`lista Piezas`);
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

listaColores();

listaUsos();

listaLineas();

listaMarcas();

listaMunicipios();

listaDepartamentos();

listaPiezas();