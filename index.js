//src/index.js
import tmi from 'tmi.js';
import path from 'node:path';
import fs from 'node:fs';
import sound from 'sound-play';
import 'dotenv/config';
import { SoundManager } from './managers/soundManager.js';
import { ChatHandler } from './handlers/chatHandler.js';
import { RaidHandler } from './handlers/raidHandler.js';
import { SoundMapper } from './mappers/soundMapper.js';
import { RaidMapper } from './mappers/raidMapper.js';


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
const SOUND_MAP = SoundMapper();
console.log('assets/sounds directory loaded', Object.keys(SOUND_MAP));

//map raids directory
const RAIDS_MAP =RaidMapper();
console.log('assets/raids directory loaded', Object.keys(RAIDS_MAP));

const soundManager = new SoundManager(SOUND_MAP);

ChatHandler(client, soundManager);
RaidHandler(client, RAIDS_MAP);


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
