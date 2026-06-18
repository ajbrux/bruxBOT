import fs from 'node:fs';
import path from 'node:path';

export function SoundMapper(dir = path.resolve('assets', 'sounds')) {
  const SOUND_MAP = {};
  if (!fs.existsSync(dir)) return SOUND_MAP;

  for (const file of fs.readdirSync(dir)) {
    const lower = file.toLowerCase();
    if (!lower.endsWith('.mp3') && !lower.endsWith('.wav')) continue;

    const chat_command = lower.replace(/\.mp3$|\.wav$/, '');
    SOUND_MAP[chat_command] = path.join(dir, file);
  }

  return SOUND_MAP;
}