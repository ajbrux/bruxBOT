import { play as playAudio } from '../audioplayers/soundPlayer.js';

export class SoundManager {
  constructor(SOUND_MAP, opts = {}) {
    this.SOUND_MAP = SOUND_MAP || {};
    this.ffplayOptions = opts.ffplayOptions || ['-nodisp', '-autoexit', '-loglevel', 'error'];
  }

  hasSound(name) {
    const key = String(name || '').trim().toLowerCase();
    return !!this.SOUND_MAP[key];
  }

  async playSound(commandCall) {
    const key = String(commandCall || '').trim().toLowerCase();
    const soundPath = this.SOUND_MAP[key];

    if (!soundPath) {
      console.log('unknown command:', key);
      return false;
    }

    try {
      const ok = await playAudio(soundPath, { ffplayOptions: this.ffplayOptions });
      if (ok) console.log('played sound:', soundPath);
      else console.log('play_failed:', soundPath);
      return ok;
    } catch (err) {
      console.log('play_failed:', err?.message || err);
      return false;
    }
  }
}