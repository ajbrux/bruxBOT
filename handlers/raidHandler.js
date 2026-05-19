// src/handlers/raidHandler.js
import { play as playAudio } from '../audioplayers/soundPlayer.js';

let raidQueue = Promise.resolve();

const RAID_FFPLAY_OPTIONS = ['-nodisp', '-autoexit', '-loglevel', 'error'];

export function RaidHandler(client, RAIDS_MAP) {
    client.on('raided', (_chan, raider, viewers) => {
        console.log(`${raider} raiding with ${viewers}`);

    const key = String(raider || '').trim().toLowerCase();
    const raidSound = RAIDS_MAP[key] || RAIDS_MAP['raid'];

    if (!raidSound) {
        console.log('missing raid sound: raid.mp3 or raid.wav');
        return;
    }

    raidQueue = raidQueue.then(async () => {
        try {
            const ok = await playAudio(raidSound, { ffplayOptions: RAID_FFPLAY_OPTIONS });
            if (ok) console.log('played raid sound:', raidSound);
            else console.log('raid_play_failed:', raidSound);
        } catch (err) {
            console.log('raid_play_failed:', err?.message || err);
        }
        });
    });
}