//mappers/soundMapper.js
import fs from 'node:fs';
import path from 'node:path';

export function SoundMapper(dir = path.resolve('assets', 'sounds')) {
    const SOUND_MAP = {};

    if(!fs.existsSync(dir)) {
    return SOUND_MAP;
    }

    const files = fs.readdirSync(dir);
    for (const file of files) {
        const file_name = file.toLowerCase();
        if (file_name.endsWith('.mp3') || file_name.endsWith('.wav')) {
            const chat_command = file_name.replace('.mp3', '').replace('.wav', '');
            SOUND_MAP[chat_command] = path.join(dir, file);
        }
    }

    return SOUND_MAP;

}