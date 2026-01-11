//managers/soundManager.js
import sound from 'sound-play';

export class SoundManager {
    constructor(SOUND_MAP) {
        this.SOUND_MAP = SOUND_MAP;
    }

    playSound(commandCall) {
    const soundPath = this.SOUND_MAP[commandCall];

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
