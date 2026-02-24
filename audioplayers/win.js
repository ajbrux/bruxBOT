//audioplayers/win.js
import player from 'sound-play';

export async function play(soundPath, { volume = undefined } = {} ) {
    try {
        await player.play(soundPath, volume, { ffplay: ffplayOptions });
        return true;
    } catch (err) {
        console.log('play_failed', err?.message || err);
        return false;
    }
}