//managers/raidManager.js
import sound from 'sound-play';


export class raidManager {
    constructor(RAID_MAP) {
        this.RAID_MAP = RAID_MAP;
    }

    playSound(commandCall) {
    const soundPath = this.RAID_MAP[commandCall];

    if (soundPath) {
        try {
            sound.play(soundPath).catch(() => {});
            console.log('played sound:', soundPath);
        } catch (err) {
            console.log('play_failed:', err);
        }
    } else {
    console.log('unknown command:', commandCall);
}}};
