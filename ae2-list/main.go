package main

import (
	"flag"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/valyala/fastjson"
)

var addr = flag.String("addr", ":8080", "http service address")
var router = mux.NewRouter()

func main() {
	flag.Parse()
	hub := newHub()
	go hub.run()

	router.Handle("/startup.lua", http.FileServer(http.Dir(".")))
	router.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		serveWs(hub, w, r)
	})

	err := http.ListenAndServe(*addr, router)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
func handleWsMessage(client *Client, message []byte) {
	value, err := fastjson.ParseBytes(message)
	if err != nil {
		log.Println(err)
		return
	}

	log.Println(value.String())

	cmd := value.GetStringBytes("cmd")
	switch string(cmd) {
	case "register":
		pattern := value.GetStringBytes("pattern")
		if r := router.GetRoute(string(pattern)); r != nil {
			r.HandlerFunc(client.handle)
		} else {
			router.HandleFunc(string(pattern), client.handle).Name(string(pattern))
		}
	case "handle":
		id := string(value.GetStringBytes("id"))
		w := requestMap[id]
		if w == nil {
			return
		}

		w.writer.Write(value.GetStringBytes("response"))
		w.mtx.Done()

		delete(requestMap, id)

	}
}
