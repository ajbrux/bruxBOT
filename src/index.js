//src/index.js
import 'dotenv/config';
import tmi from 'tmi.js';
import path from 'node:path';
import fs from 'node:fs';
import sound from 'sound-play';

//read config from .env
const username = process.env.TWITCH_BOT_USERNAME;
const token    = process.env.TWITCH_OAUTH_TOKEN;
const channel  = process.env.TWITCH_CHANNEL;

if (!username || !token || !channel) {
    console.error('username, token, or channel name are fucky');
    process.exit(1);
}

//create client
const client = new tmi.Client({
    identity: { username, password: token },
    channels: [channel],
});

//listen for chat
client.on('message', async (_chan, tags, message, self) => {
    if (self) return;

//!sound alerts

    //map the sound directory
    const SOUND_DIR = path.resolve('assets', 'sounds');
    const SOUND_MAP = {};

    const files = fs.readdirSync(SOUND_DIR);
    for (const file of files) {
        const soundPath = file.toLowerCase();
        if (soundPath.endsWith('.mp3') || soundPath.endsWith('.wav')) {
            const command = soundPath.replace('.mp3', '').replace('.wav', '');
            SOUND_MAP[command] = path.join(SOUND_DIR, file);
        }
    }

    console.log('assets/sounds directory loaded', Object.keys(SOUND_MAP));

    //!command to sound flow
    const text = message.trim().toLowerCase();
    if (!text.startsWith('!')) return;          // only look at !commands
    const commandCall = text.slice(1);                  // drop the "!"
    const soundPath = SOUND_MAP[commandCall];           // look up the command in the map


    if (soundPath) {
    try {
      sound.play(soundPath).catch(() => {});
      console.log('played sound:', soundPath);
    } catch (err) {
      console.log('play_failed:', err);
    }
    } else {
    console.log('unknown command:', commandCall);
    }

    /*
    const text = message.trim().toLowerCase();

    if (text === '!alert') {
        const SOUND_DIR = path.resolve('assets', 'sounds');
        const alertPath = path.join(SOUND_DIR, 'alert.mp3');

        if (fs.existsSync(alertPath)) {
            try {
                sound.play(alertPath).catch(() => {});
                console.log('played sound: alert.mp3');
            } catch (err) {
                console.log('play_failed:', err);
            }
        } else {
            console.log('missing file: alert.mp3');
        }
    }
    */

//print to terminal
    const name = tags['display-name'] || tags.username || 'unknown';
    console.log(`${name}: ${message}`);
});


//!emoji alerts


//listen for raid


//raid alert


//ad warning


//lifecycle logs
client.on('connected', (addr, port) => {
    console.log(`bruxBOT connected to ${addr}:${port}, listening in #${channel} as ${username}`);
});
client.on('reconnect', () => console.log('bruxBOT reconnecting...'));
client.on('disconnected', (reason) => console.log(`bruxBOT disconnected: ${reason}`));

client.connect().catch(err => {
    console.error('bruxBOT failed to connect:', err?.message || err);
    process.exit(1);
});
