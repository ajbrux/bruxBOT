//src/index.js
import tmi from 'tmi.js';
import path from 'node:path';
import fs from 'node:fs';
import sound from 'sound-play';
import 'dotenv/config';
import { SoundManager } from './managers/soundManager.js';
import { MessageHandler } from './handlers/messageHandler.js';
import { RaidHandler } from './handlers/raidHandler.js';


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

//map sounds directory
const SOUND_DIR = path.resolve('assets', 'sounds');
const SOUND_MAP = {};
const soundFiles = fs.readdirSync(SOUND_DIR);
for (const file of soundFiles) {
    const soundPath = file.toLowerCase();
    if (soundPath.endsWith('.mp3') || soundPath.endsWith('.wav')) {
        const command = soundPath.replace('.mp3', '').replace('.wav', '');
        SOUND_MAP[command] = path.join(SOUND_DIR, file);
    }
}
console.log('assets/sounds directory loaded', Object.keys(SOUND_MAP));

//map raids directory
const RAIDS_DIR = path.resolve('assets', 'raids');
const RAIDS_MAP = {};
const raidFiles = fs.readdirSync(RAIDS_DIR);
for (const file of raidFiles) {
    const raidsPath = file.toLowerCase();
    if (raidsPath.endsWith('.mp3') || raidsPath.endsWith('.wav')) {
        const raid = raidsPath.replace('.mp3', '').replace('.wav', '');
        RAIDS_MAP[raid] = path.join(RAIDS_DIR, file);
    }
}
console.log('assets/raids directory loaded', Object.keys(RAIDS_MAP));

const soundManager = new SoundManager(SOUND_MAP);

MessageHandler(client, soundManager);

RaidHandler(client, RAIDS_MAP);

//!emoji alerts

        /*
        //listen for raid
        client.on('raided', async (_chan, raider, viewers) => {
            console.log(`${raider} raiding with ${viewers}`);

            //raid alert
            const raidSound = RAIDS_MAP[raider.toLowerCase() ] || RAIDS_MAP['raid'];
            if (raidSound) {
                try {
                    sound.play(raidSound).catch(() => {});
                    console.log('played raid sound:', raidSound);
                } catch (err) {
                    console.log('raid_play_failed:', err);
                }
            } else {
                console.log('missing raid sound: raid.mp3 or raid.wav');
            }
        });
        */

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
