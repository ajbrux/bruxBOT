//overlays/overlayServer.js
import express from 'express';
import http from 'http';
import path from 'node:path';


export function OverlayServer({ port = 3030, log = console } = {}) {
    const app = express();
    const server = http.createServer(app);

    const overlayFile = path.resolve('overlays', 'wyltkmOverlay.html');
    const imagesDir = path.resolve('assets', 'images');

    app.get('/overlay', (_req, res) => res.sendFile(overlayFile));
    app.use('/assets', express.static(imagesDir));

    server.listen(port, () => log.info?.(`[overlay] http://localhost:${port}/overlay`));
    return { close: () => server.close()};
}