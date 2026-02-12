//managers/soundManager.js
import player from 'play-sound';

export class SoundManager {
    constructor(SOUND_MAP) {
        this.SOUND_MAP = SOUND_MAP;
        this.player = player ({players: ['ffplay']});
    }

    hasSound(name) {
        return !!this.SOUND_MAP[name];
    }

    playSound(commandCall) {
    const soundPath = this.SOUND_MAP[commandCall];

    if (soundPath) {
        try {
            this.player.play(
                soundPath,
                { ffplay: ['-nodisp', '-autoexit', '-loglevel', 'error']}
                )
            console.log('played sound:', soundPath);
        } catch (err) {
            console.log('play_failed:', err);
        }
    } else {
    console.log('unknown command:', commandCall);
}}};
