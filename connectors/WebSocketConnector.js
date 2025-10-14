//connectors/WebSocketConnector.js
import WebSocket from "ws";


export class WebSocketConnector {
    constructor({ backoffMs = 5000 } = {}) {
        this.ws = null;
        this.url = null;
        this.backoffMs = backoffMs;
        this.handlers = { onOpen: null, onClose: null, onError: null, onMessage: null };
    }

    setHandlers({ onOpen, onClose, onError, onMessage }) {
        this.handlers = { onOpen, onClose, onError, onMessage };
    }

    connect(url) {
        this.url = url;
        this.ws = new WebSocket(url);

        this.ws.on('open', () => this.handlers.onOpen?.());
        this.ws.on('close', (code, reason) => {
            this.handlers.onClose?.(code, reason);

            if (this.url === url) setTimeout(() => this.connect(url), this.backoffMs);
        });

        this.ws.on('error', (err) => this.handlers.onError?.(err));
        this.ws.on('message', (data) => this.handlers.onMessage?.(data));
    }

    switchUrl(nextUrl) {
        try { this.ws?.removeAllListeners(); this.ws?.close(); } catch {}
        this.connect(nextUrl);
    }

    close() {
        try { this.ws?.removeAllListeners(); this.ws?.close(); } catch {}
    }

    isConnected() {
        return this.ws?.readyState === WebSocket.OPEN;
    }
}
