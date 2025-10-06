//auth.js
import dotenv from 'dotenv';
import express from 'express';
import open from 'open';

//load .env.auth
dotenv.config({ path: ".env.auth" });

//variables
const app = express();
const port = 3000;

const CLIENT_ID = process.env.TWITCH_CLIENT_ID;
const CLIENT_SECRET = process.env.TWITCH_CLIENT_SECRET;
const REDIRECT_URI = process.env.TWITCH_REDIRECT_URI;
const SCOPES = (process.env.TWITCH_SCOPES || 'chat:read chat:edit').split(/\s+/);

if (!CLIENT_ID || !CLIENT_SECRET) {
    console.error('client creds are fucked, yo');
    process.exit(1);

}

//login and show Twitch authorize link
app.get('/login', (_req, res) => {
    const u = new URL('https://id.twitch.tv/oauth2/authorize')
    u.searchParams.set('client_id', CLIENT_ID);
    u.searchParams.set('redirect_uri', REDIRECT_URI);
    u.searchParams.set('response_type', 'code');
    u.searchParams.set('scope', );
    res.send(' <a href="${u.toString()}"> click to authorize </a> ')
});

//callback exchanges
app.get(
    '/callback', async (req, res) => {
    const code = req.query.code;

    if (!code)
        return res.status(400).send('token exchange failed');

    try {
    const tokenRes = await fetch({
        method:     'POST',
        headers:    {'Content-Type': 'application/x-www-form-urlencoded'},
        body:       new URLSearchParams ({
                        client_id: CLIENT_ID,
                        client_secret: CLIENT_SECRET, code,
                        grant_type: 'authorization_code',
                        redirect_uri: REDIRECT_URI
                    })
    });

    //!tokens => kick error
    const data = await tokenRes.json();
    if (!tokenRes.ok) {
        console.error('tokens are fucked, yo', data);
        return res.status(500).send('fucked tokens');
    }

    //token to console
//    console.log('ACCESS TOKEN: ${data.access_token}' );
//    console.log('REFRESH TOKEN: ${data.refresh_token}' );

    console.log('ACCESS TOKEN: SUCCESS' );
    console.log('REFRESH TOKEN: SUCCESS' );

    //token to local host
    res.send(`
        <p>${data.access_token}</p>
        <p>${data.refresh_token}</p>
    `);

    } catch (e) {
        console.error('callback exchanges fucked', e);
        res.status(500).send('unfuck the callback exchanges');
    }
});




//start local server, open browser
app.listen(
    port, async () => {
        try {await open('http://localhost:${port}/login');
        } catch {}
    }
);


