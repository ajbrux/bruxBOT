//managers/soundManager.js
import { play as playAudio } from '../audioplayers/soundPlayer.js';

export class SoundManager {
    constructor(SOUND_MAP) {
        this.SOUND_MAP = SOUND_MAP;
        this.ffplayOptions = ['-nodisp', '-autoexit', '-loglevel', 'error']
    }

    hasSound(name) {
    const key = String(name || '').trim().toLowerCase();
        return !!this.SOUND_MAP[name];
    }

    async playSound(commandCall) {
        const key = String(commandCall || '').trim().toLowerCase();
        const soundPath = this.SOUND_MAP[key];

        if (!soundPath) {
            console.log('unknown command: ', key);
            return false
        }

        const ok = await playAudio(soundPath, { ffplayOptions: this.ffplayOptions });
        if (ok)
            console.log('played sound: ', soundPath);
        else {
            console.log('play_failed:', soundPath);
        return ok;
        }
    }
}
