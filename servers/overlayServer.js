//overlays/overlayServer.js
import express from 'express';
import http from 'http';
import path from 'node:path';
import fs from 'node:fs';


export function OverlayServer({ port = 3030, log = console } = {}) {
    const app = express();
    const server = http.createServer(app);

    const overlayFile = path.resolve('overlays', 'wyltkmOverlay.html');
    const imagesDir = path.resolve('assets', 'images');

    app.get('/overlay', (_req, res) => res.sendFile(overlayFile));

    app.use('/images', express.static(imagesDir));

    app.get('/overlay/images.json', (_req, res) => {
        try {
            const files = fs.readdirSync(imagesDir)
                .filter(f => /\.(png|jpg|jpeg|gif|webp)$/i.test(f))
                .sort((a,b) => a.localeCompare(b, undefined, {numeric: true, sensitivity: 'base' }));
            res.json({ files });
        } catch (e) {
            log.error?.('overlay list error:', e);
            res.status(500).json({ files: [] });
        }
    })

    server.listen(port, () => log.info?.(`[overlay] http://localhost:${port}/overlay`));
    return { close: () => server.close()};
}