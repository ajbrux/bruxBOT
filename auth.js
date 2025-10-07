//auth.js   /////debug build/////
import dotenv from 'dotenv';
import express from 'express';
import open from 'open';

dotenv.config({ path: '.env.auth' });

//variables
const app = express();
const port = 3000;

const CLIENT_ID = process.env.TWITCH_CLIENT_ID;
const CLIENT_SECRET = process.env.TWITCH_CLIENT_SECRET;
const REDIRECT_URI = process.env.TWITCH_REDIRECT_URI || `http://localhost:${port}/callback`;
const SCOPES = (process.env.TWITCH_SCOPES || 'chat:read chat:edit').split(/\s+/);

const TWITCH_AUTHORIZE_URL = 'https://id.twitch.tv/oauth2/authorize';
const TWITCH_TOKEN_URL = 'https://id.twitch.tv/oauth2/token';

/////request logger/////
            app.use((req, _res, next) => {
                console.log('[req]', req.method, req.url);
                next();
            });

/////credential check/////
            if (!CLIENT_ID || !CLIENT_SECRET) {
                console.error('client creds are fucked, yo');
                process.exit(1);
            }

//login
app.get('/login', (_req, res) => {
    const u = new URL(TWITCH_AUTHORIZE_URL);
    u.searchParams.set('client_id', CLIENT_ID);
    u.searchParams.set('redirect_uri', REDIRECT_URI);
    u.searchParams.set('response_type', 'code');
    u.searchParams.set('scope', SCOPES.join(' '));

/////login debug html/////
            const debug = {
                usingRedirectUri: REDIRECT_URI,
                clientIdPrefix: CLIENT_ID.slice(0, 6),
                scopes: SCOPES,
                authorizeUrl: u.toString(),
            };

            console.log('[auth] /login debug', debug);

            res.send(`
            <h2>Twitch OAuth</h2>
            <p><a href="${u.toString()}">Authorize with Twitch</a></p>
            <details open><summary>debug</summary><pre>${escapeHtml(JSON.stringify(debug, null, 2))}</pre></details>
            `);
});

//callback
app.get('/callback', async (req, res) => {
    const code = req.query.code?.toString();

/////callback diagnostic/////
            if (!code) {
                const msg = { error: 'Missing ?code', query: req.query };
                console.error('[auth] /callback missing code', msg);
                return res.status(400).send(`<pre>${escapeHtml(JSON.stringify(msg, null, 2))}</pre>`);
            }

/////outgoing debug
            const outgoing = {
                clientIdPrefix: CLIENT_ID.slice(0, 6),
                clientIdLength: CLIENT_ID.length,
                hasClientSecret: Boolean(CLIENT_SECRET),
                redirectUri: REDIRECT_URI,
                codeLength: code.length,
            };
            console.log('[auth] outgoing token request', outgoing);

//basic auth header
function toBasic(id, secret) {
    return Buffer.from(`${id}:${secret}`).toString('base64');
}


const form = new URLSearchParams({
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    grant_type: 'authorization_code',
    code,
    redirect_uri: REDIRECT_URI,
});

try {
const resp = await fetch(TWITCH_TOKEN_URL, {
    method: 'POST',
    headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': `Basic ${toBasic(CLIENT_ID, CLIENT_SECRET)}`
    },
    body: form,
});

/////incoming debug/////
            const raw = await resp.text();
            let data; try { data = JSON.parse(raw); } catch { data = { raw }; }

            const details = {
                status: resp.status,
                statusText: resp.statusText,
                response: data,
                sentBody: Object.fromEntries(form.entries()),
                outgoing,
            };

            console.log('[auth] incoming token response', details);

/////error response/////
            if (!resp.ok) {
                return res
                    .status(500)
                    .send(`<pre>Token exchange failed.\n\n${escapeHtml(JSON.stringify(details, null, 2))}</pre>`);
            }

//tokens to terminal
console.log(`ACCESS TOKEN: oauth:${data.access_token}`);
console.log(`REFRESH TOKEN: ${data.refresh_token}`);

//tokens to html
return res.send(`
    <h2>Success</h2>
    <pre>TWITCH_OAUTH_TOKEN=oauth:${data.access_token}</pre>
    <pre>REFRESH_TOKEN=${data.refresh_token}</pre>

/////debug to html/////
            <details open><summary>details</summary><pre>${escapeHtml(JSON.stringify(details, null, 2))}</pre></details>

`);

} catch (e) {
    const msg = { error: e?.message || String(e) };
    console.error('[auth] network/code error', e);
    return res.status(500).send(`<pre>Internal error during token exchange.\n\n${escapeHtml(JSON.stringify(msg, null, 2))}</pre>`);
}
});

//helper to embed JSON in HTML
function escapeHtml(s) {
    return String(s)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
}

//start server & auto-open
app.listen(port, async () => {
    console.log(`Auth server running at http://localhost:${port}`);
    console.log(`Open http://localhost:${port}/login to start`);
    try { await open(`http://localhost:${port}/login`); } catch {}
});
