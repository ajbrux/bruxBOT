//connectors/WebSocketConnector.js
import WebSocket from "ws";


export class WebSocketConnector {
    constructor({ backoffMs = 5000 } = {}) {
        this.ws = null;
        this.url = null;
        this.backoffMs = backoffMs;
        this.shouldReconnect = true;
        this.handlers = { onOpen: null, onClose: null, onError: null, onMessage: null };
    }

    setHandlers({ onOpen, onClose, onError, onMessage }) {
        this.handlers = {
            onOpen:    onOpen    || this.handlers.onOpen,
            onClose:   onClose   || this.handlers.onClose,
            onError:   onError   || this.handlers.onError,
            onMessage: onMessage || this.handlers.onMessage,
        };
    }

    connect(url) {
        if (this.ws && (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING)) {
              return;
        }
        this.shouldReconnect = true;
        this.url = url;
        this.ws = new WebSocket(url);
        this.ws.on('open', () => this.handlers.onOpen?.());
        this.ws.on('close', (code, reason) => {
            const reason_type = typeof reason === 'string' ? reason : reason?.toString?.() || '';
            this.handlers.onClose?.(code, reason_type);
            if (this.shouldReconnect && this.url === url) setTimeout(() => this.connect(url), this.backoffMs);
        });
        this.ws.on('error', (err) => this.handlers.onError?.(err));
        this.ws.on('message', (data) => this.handlers.onMessage?.(data));
    }

    switchUrl(nextUrl) {
        try { this.ws?.removeAllListeners(); this.ws?.close(); } catch {}
        this.connect(nextUrl);
    }

    close() {
        this.shouldReconnect = false;
        try { this.ws?.removeAllListeners(); this.ws?.close(); } catch {}
    }

    isConnected() {
        return this.ws?.readyState === WebSocket.OPEN;
    }
}
