package http_websocket_bridge

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

type httpWebsocketBridge struct {
	r   *mux.Router
	hub *Hub
}

func New(r *mux.Router) *httpWebsocketBridge {
	return &httpWebsocketBridge{
		r:   r,
		hub: newHub(r),
	}
}

func (b *httpWebsocketBridge) Run() {
	go b.hub.run()
}

func (b *httpWebsocketBridge) HandleWebsocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}

	client := &Client{hub: b.hub, conn: conn, send: make(chan []byte, 256)}
	client.hub.register <- client

	go client.writePump()
	go client.readPump()
}
