// src/index.js
import 'dotenv/config';
import tmi from 'tmi.js';

//read config from .env
const username = process.env.TWITCH_BOT_USERNAME;
const token    = process.env.TWITCH_OAUTH_TOKEN;
const channel  = process.env.TWITCH_CHANNEL;

if (!username || !token || channel) {
    //kick error
}

//create client
const client = new tmi.Client({
    identity: { username, password: token },
    channels:[channels]
});


//listen for chat
client.on('message', async (_chan, tags, message, self) => {
    if (self) return;


//!sound alerts


//!emoji alerts



//listen for raid



//raid alert



//print to terminal
  const name = tags['display-name'] || tags.username || 'unknown';
  console.log(`${name}: ${message}`);

//parser