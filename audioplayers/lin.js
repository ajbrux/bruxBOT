//audioplayers/lin.js
import { spawn } from 'node:child_process';

const DEFAULT_FFPLAY = ['-nodisp', '-autoexit', 'loglevel', 'error'];

export async function play(soundPath, { ffplayOptions = DEFAULT_FFPLAY } = {}) {
    return new Promise( (resolve) => {
        const args = [...ffplayOptions, soundPath];
        const child = spawn('ffplay', args, { stdio: 'ignore' });

        child.on('error', (err) => {
            console.log('play_failed:', err?.message || err);
            resolve(false);
        });

        child.on('close', (code) => {
            resolve(code === 0);
        });
    });
}
