//servers/overlayServer.js
import express from 'express';
import http from 'http';
import path from 'node:path';
import { ImageMapper } from '../mappers/imageMapper.js';

export function OverlayServer({ port = 3030, imagesMeta, log = console } = {}) {
    const app = express();
    const server = http.createServer(app);

    const overlayFile = path.resolve('overlays', 'wyltkmOverlay.html');
    const imagesDir = path.resolve('assets', 'images');

    app.get('/overlay', (_req, res) => res.sendFile(overlayFile));
    app.use('/images', express.static(imagesDir));

    const { files } = ImageMapper({ dir: imagesDir, slotHeight: 128, gap: 8 });

    app.get('/overlay/images.json', (_req, res) => {
        const items = (Array.isArray(files) ? files : [])
            .map(f => {
                if (!f) return null;
                if (typeof f === 'string') {
                    const id = f.replace(/\.[^.]+$/, '');
                    return {
                        id,
                        title: id.replace(/[_-]/g, ' ').toUpperCase(),
                        src: `/images/${f}`,
                    };
                }
                if (f.file) {
                    return { id: f.id, title: f.title, src: `/images/${f.file}` };
                }
                return null;
            })
            .filter(Boolean);

        res.json({ items });
    });

    server.listen(port, () => log.info?.(`[overlay] http://localhost:${port}/overlay`));
    return { close: () => server.close() };
}