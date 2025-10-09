//handlers/messageHandlers.js
import sound from 'sound-play';


export function MessageHandler(client, soundManager) {
    client.on('message', async (_chan, tags, message, self) => {
        if (self) return;

    //print to terminal
    const name = tags['display-name'] || tags.username || 'unknown';
    console.log(`${name}: ${message}`);

    //!command parser
    const text = message.trim().toLowerCase();
    if (!text.startsWith('!')) return;

    const commandCall = text.slice(1);

    soundManager.playSound(commandCall)
            /*
            const soundPath = SOUND_MAP[commandCall];

            if (soundPath) {
            try {
                sound.play(soundPath).catch(() => {});
                console.log('played sound:', soundPath);
            } catch (err) {
                console.log('play_failed:', err);
            }
            } else {
            console.log('unknown command:', commandCall);
            }
            */
  });
}