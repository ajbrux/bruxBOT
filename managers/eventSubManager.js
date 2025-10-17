// eventSubManager.js
import fetch from 'node-fetch';
import EventEmitter from 'events';
import { WebSocketConnector } from '../connectors/WebSocketConnector.js';


export class EventSubManager extends EventEmitter {
    constructor(clientID, token, broadcasterID, connector = new WebSocketConnector()) {
        super();
        this.clientID = clientID;
        this.token = token;
        this.broadcasterID = broadcasterID;
        this.sessionID = null;
        this.connector = connector;
        this.connector.setHandlers({
            onOpen:     () => this.emit('socket_open'),
            onClose:    (code, reason) => this.emit('socket_close', {code, reason}),
            onError:    (err) => this.emit('socket_error', err),
            onMessage:  (data) => this.#handleMessage(data),
        });
    }

    connect() {
        this.connector.connect('wss://eventsub.wss.twitch.tv/ws');
    }

    #handleMessage(data) {
        let event_message;
        try {
                const text = (typeof data === 'string') ? data : data?.toString?.() ?? String(data);
                event_message = JSON.parse(data);
            }
        } catch {
            this.emit('bad_json', data);
            return;
        }

        const { metadata, payload } = event_message;
        const em_type = metadata?.message_type;

        switch (em_type) {
            //lifecycle
            case 'session_welcome': {
                this.sessionID = payload?.session?.id || null;
                this.emit('session_welcome', payload);
                this.emit('ready', this.sessionID);
                break;
            }
            case 'session_keepalive': {
                this.emit('session_keepalive', payload ?? null);
                break;
            }
            case 'session_reconnect': {
                this.emit('session_reconnect', payload);
                const url = payload?.session?.reconnect_url;
                if (url) this.connector.switchUrl(url);
                break;
            }

            //event
            case 'notification': {
                this.emit('notification', payload); // catch-all
                const type = payload?.subscription?.type;
                const event = payload?.event;
                if (type) this.emit(type, event);   // typed event e.g. 'channel.ad_break.begin'
                break;
            }
            case 'revocation': {
                this.emit('revocation', payload);
                break;
            }

            //catch
            default: {
                this.emit("unknown_message",em_type)
            }
        }
    }

    async subscribe(eventType, version = '1') {
        //preflight checks
        if (!this.clientID || !this.token || !this.broadcasterID) {
            console.error('bruxBOT has fucked up credentials');
            return;
        }

        try {
        const response = await fetch('https://api.twitch.tv/helix/eventsub/subscriptions', {
            method: 'POST',
            headers: {
            'Client-ID': this.clientID,
            'Authorization': `Bearer ${this.token}`,
            'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                type: eventType,
                version,
                condition: { broadcaster_user_id: this.broadcasterID },
                transport: {
                    method: 'websocket',
                    session_id: this.sessionID,
                },
            }),
        });

        const result = await response.json();

        if (!response.ok) {
            console.error(`bruxBOT failed to subscribe to ${eventType}:`, result);
        } else {
            console.log(`bruxBOT subscribed to ${eventType}`);
        }
        } catch (err) {
            console.error('bruxBOT Subscription network error:', err);
        }
    }
}
