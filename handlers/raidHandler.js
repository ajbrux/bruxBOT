// src/handlers/raidHandler.js
export function RaidHandler(client, soundManager, RAIDS_MAP) {
    client.on('raided', (_chan, raider, viewers) => {
        console.log(`${raider} raiding with ${viewers}`);

        const key = String(raider || '').trim().toLowerCase();
        const raidSound = RAIDS_MAP[key] || RAIDS_MAP['raid'];

        if (!raidSound) {
            console.log('missing raid sound: raid.mp3 or raid.wav');
            return;
        }

        // Uses the same queue + ffplay options as chat sounds
        soundManager.playPath(raidSound, { logLabel: `raid:${key || 'unknown'}` });
    });
}