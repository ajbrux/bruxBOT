//src/index.js
import 'dotenv/config';
import tmi from 'tmi.js';

//read config from .env
const username = process.env.TWITCH_BOT_USERNAME;
const token    = process.env.TWITCH_OAUTH_TOKEN;
const channel  = process.env.TWITCH_CHANNEL;

if (!username || !token || !channel) {
    console.error('username, token, or channel name are fucky');
    process.exit(1);
}

//create client
const client = new tmi.Client({
    identity: { username, password: token },
    channels: [channel],
});

//listen for chat
client.on('message', async (_chan, tags, message, self) => {
    if (self) return;


//!sound alerts


//!emoji alerts


//listen for raid
client.on('raided', async (_chan, raider, viewers) => {
    console.log(`${raider} raiding with ${viewers}`);

//raid alert


//print to terminal
const name = tags['display-name'] || tags.username || 'unknown';
console.log(`${name}: ${message}`);
});

//lifecycle logs
client.on('connected', (addr, port) => {
    console.log(`bruxBOT is connected to ${addr}:${port}, listening in #${channel} as ${username}`);
});
client.on('reconnect', () => console.log('bruxBOT is reconnecting...'));
client.on('disconnected', (reason) => console.log(`bruxBOT disconnected: ${reason}`));
client.connect().catch(err => {
    console.error('bruxBOT failed to connect:', err?.message || err);
    process.exit(1);
});
