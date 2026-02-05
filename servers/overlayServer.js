//servers/overlayServer.js
import express from 'express';
import http from 'http';
import path from 'node:path';
import { ImageMapper } from '../mappers/imageMapper.js';

export function OverlayServer({ port = 3030, log = console } = {}) {
    const app = express();
    const server = http.createServer(app);

    const overlayRoot = path.resolve('overlays', 'CodexArtGallery', 'html');
    const imagesDir = path.resolve('assets', 'images');

    app.use('/overlay', express.static(overlayRoot));
    app.get('/overlay', (_req, res) => {
        res.sendFile(path.join(overlayRoot, 'CodexArtGallery.html'));
    });

    app.use('/images', express.static(imagesDir));

    const { files } = ImageMapper({ dir: imagesDir });

    app.get('/overlay/images.json', (_req, res) => {
        const items = (Array.isArray(files) ? files : [])
            .map(f => {
                if (!f) return null;
                return { id: f.id, title: f.title, src: `/images/${f.file}` };
            })
            .filter(Boolean);

        res.json({ items });
    });

    server.listen(port, () => {
        log.info?.(`[overlay] http://localhost:${port}/overlay`);
        log.info?.(`[overlay] images.json to http://localhost:${port}/overlay/images.json`);
        });
    return { close: () => server.close() };
}