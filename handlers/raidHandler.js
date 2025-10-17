//handlers/raidHandler.js
import sound from 'sound-play';

export function RaidHandler (client, RAIDS_MAP) {
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
    }