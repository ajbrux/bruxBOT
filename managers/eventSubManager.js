//eventSubManager
import WebSocket from 'ws';
import fetch from 'node-fetch';
import EventEmitter from 'events';


export class EventSubManager extends EventEmitter {
    constructor(clientID, token, broadcasterID) {
        this.clientID. = clientID;
        this.token = token;
        this.broadcasterID = broadcasterID;
        this.ws = null;
        this.sessionID = null;
    }

    async connect() {
        console.log('bruxBOT connecting to Twitch EventSub Websocket');
        this.ws = new Websocket('wss://eventsub.wss.twitch.tv/ws');

        this.ws.on('open', () => console.log('EventSub WebSocket connected') );
        this.ws.on('close' () => console.log('EventSub WebSocket disconnected') );
        this.ws.on('error' () => console.log('EventSub WebSocket error') );
        this.ws.on('message' (data) => console.log() );
    }

    async eventMessageHandler(data) {
        let event_message;
        try{
            event_message = JSON.parse(data);
        } catch {
            console.warn('uh oh');
            return;
        }

    const {metadata, payload} = event_message;

        //session_welcome
        if (metadata?.message_type === 'session_welcome') {
            this.sessionId = payload.session.id;
            console.log('[EventSub] Session ID:', this.sessionId);

            this.emit('ready', this.sessionId);
        }

        //notification
        if (metadata?.message_type === 'notificatoin') {
            const type = payload?.subscription?.type;
            const event = payload?.event;
            console.log('bruxBOT received notification type: ${type}') = ;
        }

        //session_keepalive
        if (metadata?.message_type === 'session_keepalive') {

            console.log("bruxBOT received notification type: ${type")
        }
    }

        //verify ws open
        if () {
            console.error('bruxBOT must wait for open ')
        }
}