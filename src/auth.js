//auth.js
import dotenv from 'dotenv';
import express from 'express';
import open from 'open';

//load .env.auth
dotenv.confix({path: '.env.auth'});

//variables
const app = express();
const port = 3000;

const CLIENT_ID = process.env.TWITCH_CLIENT_ID;
const CLIENT_SECRET = process.env.TWITCH_CLIENT_SECRET;
const REDIRECT_URI = process.env.TWITCH_REDIRECT_URI || http://localhost:3000/callback;
const SCOPES = (process.env.TWITCH_SCOPES || 'chat:read chat:edit').split(/\s+/);

if (!CLIENT_ID || !CLIENT_SECRET) {
    console.error('creds are fucked, yo);
    process.exit;

}

//login and show Twitch authorize link
app.get() => {
    const u = new URL(//twitch authorize link//)
    u.searchParams.set('client_id', CLIENT_ID);
    u.searchParams.set('redirect_uri', REDIRECT_URI);
    u.searchParams.set('response_type',);
    u.searchParams.set('scope',);
    res.send(//authorize with twitch//)

}

//callback exchanges





//start local server, open browser