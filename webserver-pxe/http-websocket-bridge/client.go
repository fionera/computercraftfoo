package http_websocket_bridge

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

type Client struct {
	hub  *Hub
	conn *websocket.Conn
	send chan []byte
}

func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error { c.conn.SetReadDeadline(time.Now().Add(pongWait)); return nil })
	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}
		c.hub.handleWsMessage(c, message)
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()
	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			n := len(c.send)
			for i := 0; i < n; i++ {
				w.Write(<-c.send)
			}

			if err := w.Close(); err != nil {
				return
			}
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

var requestMap = struct {
	r   map[string]*requestCycle
	mtx *sync.RWMutex
}{
	r:   make(map[string]*requestCycle),
	mtx: &sync.RWMutex{},
}

type requestCycle struct {
	writer  http.ResponseWriter
	request *http.Request
	wg      *sync.WaitGroup
}

type Request struct {
	IP     string `json:"ip"`
	Method string `json:"method"`
	Url    string `json:"url"`
	Id     string `json:"id"`
	Body   string `json:"body"`
}

func (c *Client) handle(writer http.ResponseWriter, request *http.Request) {
	id := rand.Int()

	body, err := ioutil.ReadAll(request.Body)
	if err != nil {
		log.Println(err)
		return
	}

	r := Request{
		IP:     request.RemoteAddr,
		Method: request.Method,
		Url:    request.URL.String(),
		Id:     fmt.Sprintf("%d", id),
		Body:   string(body),
	}
	data, err := json.Marshal(&r)
	if err != nil {
		log.Println(err)
		return
	}

	m := sync.WaitGroup{}
	m.Add(1)
	requestMap.mtx.Lock()
	requestMap.r[r.Id] = &requestCycle{
		writer:  writer,
		request: request,
		wg:      &m,
	}
	requestMap.mtx.Unlock()

	defer func() {
		if r := recover(); r != nil {
			writer.WriteHeader(500)
			m.Done()
			fmt.Println("Recovered: ", r)
		}
	}()

	c.send <- data
	m.Wait()
}
