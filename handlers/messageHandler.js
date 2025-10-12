//handlers/messageHandlers.js
import sound from 'sound-play';


export function MessageHandler(client, soundManager) {
    client.on('message', async (_chan, tags, message, self) => {
    const adbreak = 'we are taking a quick ad break. thanks for hanging out.';

        if (self) return;

    //print to terminal
    const name = tags['display-name'] || tags.username || 'unknown';
    console.log(`${name}: ${message}`);

    //ad warning parser
    /*detect ad break*/
    client.say(channel, adbreak)

    //!command parser
    const text = message.trim().toLowerCase();
    if (!text.startsWith('!')) return;

    const commandCall = text.slice(1);

    soundManager.playSound(commandCall)

  });
}