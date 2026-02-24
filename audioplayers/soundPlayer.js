//audioplayers/soundPlayer.js
import * as win from './win.js'
import * as lin from './lin.js'

let OS = null;

export function initSoundPlayer(detectedOS) {
    OS = detectedOS;
    console.log('[soundplayer] intialized for:', OS);
}

export async function play(soundPath, options = {}) {
    if (!OS) {
        console.log();
        return false;
    }

    if (OS === 'windows')
        return win.play(soundPath, options);

    return lin.play(soundPath, options);
}