//eventSubManager
import WebSocket from 'ws';
import fetch from 'node-fetch';
import EventEmitter from 'events';

export class EventSubManager {
    constructor(token, userID, onAdBreak) {
        this.token = token;
        this.userId = userId;
        this.onAdBreak = onAdBreak;
        this.ws = null;
    }

    connect() {
        console.log('bruxBOT connecting to Twitch EventSub Websocket');
        this.ws = new Websocket('');
    }

    async eventSubHandler() {
        //parse event metadata//
    }




}