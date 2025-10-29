//mappers/ImageMapper.js
import fs from 'node:fs';
import path from 'node:path';
import { imageSize } from 'image-size';


export function ImageMapper({
    dir = path.resolve('assets', 'images'),
    titleCase = 'upper',
} = {}) {
    if (!fs.existsSync(dir)) {
        return { files: [] };
    }

    const files = fs.readdirSync(dir)
        .filter(f => /\.(webp)$/i.test(f))
        .sort((a, b) => a.localeCompare(b, undefined, {numeric:true, sensitivity: 'base'}))
        .map(file => {
            const id = file.replace(/\.[^.]+$/, '');
            let title = id.replace(/[_-]/g, ' ');
            if (titleCase === 'upper') title = title.toUpperCase();
            return { file, id, title };
            });

    return { files };
}