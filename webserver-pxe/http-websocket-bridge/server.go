package http_websocket_bridge

import (
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/valyala/fastjson"
)

const (
	// Time allowed to write a message to the peer.
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer.
	pongWait = 60 * time.Second

	// Send pings to peer with this period. Must be less than pongWait.
	pingPeriod = (pongWait * 9) / 10
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type Hub struct {
	clients    map[*Client]bool
	register   chan *Client
	unregister chan *Client
	router     *mux.Router
}

func newHub(r *mux.Router) *Hub {
	return &Hub{
		router:     r,
		register:   make(chan *Client),
		unregister: make(chan *Client),
		clients:    make(map[*Client]bool),
	}
}

func (h *Hub) run() {
	for {
		select {
		case client := <-h.register:
			h.clients[client] = true
		case client := <-h.unregister:
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}
		}
	}
}

func (h *Hub) handleWsMessage(c *Client, message []byte) {
	value, err := fastjson.ParseBytes(message)
	if err != nil {
		log.Println(err)
		return
	}

	cmd := value.GetStringBytes("cmd")
	switch string(cmd) {
	case "register":
		pattern := string(value.GetStringBytes("pattern"))
		if r := h.router.GetRoute(pattern); r != nil {
			log.Printf("Overriding route `%s`\n", pattern)
			r.HandlerFunc(c.handle)
		} else {
			log.Printf("Registering route `%s`\n", pattern)
			h.router.HandleFunc(pattern, c.handle).Name(pattern)
		}

	case "chunk":
		id := string(value.GetStringBytes("id"))
		log.Printf("Chunk for request `%s`\n", id)
		requestMap.mtx.RLock()
		w := requestMap.r[id]
		requestMap.mtx.RUnlock()
		if w == nil {
			return
		}

		w.writer.Write(value.GetStringBytes("response"))

	case "handle":
		id := string(value.GetStringBytes("id"))
		log.Printf("Handling request `%s`\n", id)
		requestMap.mtx.RLock()
		w := requestMap.r[id]
		requestMap.mtx.RUnlock()
		if w == nil {
			return
		}

		w.wg.Done()

		requestMap.mtx.Lock()
		delete(requestMap.r, id)
		requestMap.mtx.Unlock()

	}
}
