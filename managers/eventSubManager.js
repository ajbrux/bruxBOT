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
            if (typeof data !== "string") {
                event_message = JSON.parse(data);
            }
        } catch {
            this.emit('bad_json', data);
            return;
        }

        const { metadata, payload } = event_message;
        const em_type = metadata?.message_type;

        switch (em_type) {
            case 'session_welcome': {}
            case 'session_keepalive': {}
            case 'session_reconnect': {}
            case 'notification': {}
            case 'revocation': {}
            default:
                this.emit("unknown_message",em_type)
        }
    }



    async subscribe(eventType, version = '1') {
        //checks
        if (!this.sessionID) {
            console.error('bruxBOT must wait for open WebSocket');
            return;
        }
        if (!this.clientID || !this.token || !this.brodcasterID) {
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
