const rpc = require('discord-rpc');
const http = require('http');

const client = new rpc.Client({
    transport: 'ipc'
});

const clientId = '891457965889032242';
const port = 31415;

http.createServer((req, res) => {
    if (req.method === 'POST') {
        let body = '';
        req.on('data', (data) => {
            body += data;
        });
        req.on('end', () => {
            body = JSON.parse(body);

            client.setActivity({
                startTimestamp: body.Timestamp,
                largeImageKey: 'studio-icon',
                largeImageText: 'Roblox Studio',
                details: body.Details,
                state: body.State,
                instance: false
            }).then(() => {
                console.log(`\x1b[32m[robloxstudio-rpc]\x1b[0m ${body.Details}${body.State ? ` | ${body.State}` : ''}`);

                res.writeHead(200);
                res.write('Success');
                res.end();
            }).catch((err) => {
                console.log(`\x1b[41m[robloxstudio-rpc]\x1b[0m An error occurred!`);
                console.log(err);

                res.writeHead(500);
                res.write('Failure');
                res.end();
            });
        });
    } else if (req.method === 'DELETE') {
        client.setActivity({}).then(() => {
            console.log(`\x1b[33m[robloxstudio-rpc]\x1b[0m Stopped rich presence`);

            res.writeHead(200);
            res.write('Killed');
            res.end();
        });
    } else {
        res.writeHead(200);
        res.write('POST request only');
        res.end();
    }
}).listen(port, () => {
    console.log(`\x1b[32m[robloxstudio-rpc]\x1b[0m Started! Listening at http://localhost:${port}!`);

    client.login({
        clientId
    }).catch(console.error);
});