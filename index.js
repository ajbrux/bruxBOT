//src/index.js
import tmi from 'tmi.js';
import path from 'node:path';
import fs from 'node:fs';
import 'dotenv/config';
import { SoundManager } from './managers/soundManager.js';
import { ChatHandler } from './handlers/chatHandler.js';
import { RaidHandler } from './handlers/raidHandler.js';
import { SoundMapper } from './mappers/soundMapper.js';
import { RaidMapper } from './mappers/raidMapper.js';
import { ImageMapper } from './mappers/imageMapper.js';
import { OverlayServer } from './servers/overlayServer.js';
import { detectOS } from './osdetector/osDetector.js';
import { initSoundPlayer } from './audioplayers/soundPlayer.js'


//spool up local overlay server
const OVERLAY_PORT = Number(process.env.OVERLAY_PORT) || 3030;
const IMAGES_META = ImageMapper({ slotHeight: 120, gap: 12 });
const overlay = OverlayServer({ port: OVERLAY_PORT});



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

const OS = detectOS();
initSoundPlayer(OS);

//map sounds directory
const SOUND_MAP = SoundMapper();
console.log('assets/sounds directory loaded', Object.keys(SOUND_MAP));

//map raids directory
const RAIDS_MAP =RaidMapper();
console.log('assets/raids directory loaded', Object.keys(RAIDS_MAP));

const IMAGE_MAP = {}
const imageFiles = IMAGES_META.files || [];

for(const f of imageFiles) {
    IMAGE_MAP[f.id.toLowerCase()] = f;
}
console.log('assets/images directory loaded', Object.keys(IMAGE_MAP));

const soundManager = new SoundManager(SOUND_MAP);

ChatHandler(client, soundManager, overlay, IMAGE_MAP);
RaidHandler(client, RAIDS_MAP);

// DEBUG: simulate a raid from the console after startup
if (process.env.DEBUG_RAID === '1') {
  setTimeout(() => {
    const fakeRaider = process.env.DEBUG_RAIDER || 'someStreamer';
    const fakeViewers = Number(process.env.DEBUG_VIEWERS || 42);
    client.emit('raided', channel, fakeRaider, fakeViewers);
    console.log('[debug] emitted raided:', fakeRaider, fakeViewers);
  }, 2000);
}

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
