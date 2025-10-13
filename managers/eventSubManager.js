// eventSubManager.js
import WebSocket from 'ws';
import fetch from 'node-fetch';
import EventEmitter from 'events';


export class EventSubManager extends EventEmitter {
    constructor(clientID, token, broadcasterID) {
        this.clientID = clientID;
        this.token = token;
        this.broadcasterID = broadcasterID;
        this.ws = null;
        this.sessionID = null;
    }

    async connect() {
        console.log('bruxBOT connecting to Twitch EventSub WebSocket');
        this.ws = new WebSocket('wss://eventsub.wss.twitch.tv/ws');

        this.ws.on('open', () => console.log('EventSub WebSocket connected') );
        this.ws.on('close', () => console.log('EventSub WebSocket disconnected') );
        this.ws.on('error', (err) => console.error('EventSub WebSocket error:', err));
        this.ws.on('message', (data) => this.eventMessageHandler(data));
    }

    async eventMessageHandler(data) {
        let event_message;
        try {
            event_message = JSON.parse(data);
        } catch {
            console.warn('uh oh — bad JSON:', data);
            return;
        }

    const {metadata, payload} = event_message;

        //session_welcome
        if (metadata?.message_type === 'session_welcome') {
            this.sessionID = payload.session.id;
            console.log('[EventSub] Session ID:', this.sessionID);

            this.emit('ready', this.sessionID);
        }

    //notification
    if (metadata?.message_type === 'notification') {
        const type = payload?.subscription?.type;
        const event = payload?.event;
        console.log(`bruxBOT received notification type: ${type}`);
        this.emit(type, event);
    }

        //session_keepalive
        if (metadata?.message_type === 'session_keepalive') {
            console.log("bruxBOT received notification type: ${type")
        }
    }

    async subscribe(eventType, version = '1') {
        if (!this.sessionID) {
            console.error('bruxBOT must wait for open WebSocket');
            return;
        }

        console.log(`bruxBOT subscribing to ${eventType}...`);

        try {
        const response = await fetch('https://api.twitch.tv/helix/eventsub/subscriptions', {
            method: 'POST',
            headers: {
            'Client-ID': this.sessionID,
            'Authorization': `Bearer ${this.token}`,
            'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                type: eventType,
                version,
                condition: { broadcaster_user_id: this.sessionID },
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
