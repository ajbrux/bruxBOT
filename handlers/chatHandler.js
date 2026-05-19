//handlers/chatHandler.js
export function ChatHandler(client, soundManager, overlay, IMAGE_MAP) {
  client.on('message', async (_chan, tags, message, self) => {
    if (self) return;

    //print to terminal
    const name = tags['display-name'] || tags.username || 'unknown';
    console.log(`${name}: ${message}`);

    //ad warning parser
    /*detect ad break*/
    //client.say(channel, adbreak)

    //!command parser
    const text = message.trim().toLowerCase();
    if (!text.startsWith('!')) return;

    const chat_command = text.slice(1).trim();
    if (!chat_command) return;

    //soundManager.playSound(chat_command)
    if (soundManager.hasSound(chat_command)) {
        await soundManager.playSound(chat_command);
        return;
    }

    if (IMAGE_MAP[chat_command]) {
        overlay.broadcast({ type: "image_call", title: chat_command });
        console.log('[overlay] image_call', chat_command);
        return;
    }

    console.log('unknown command: ', chat_command);
  });
}