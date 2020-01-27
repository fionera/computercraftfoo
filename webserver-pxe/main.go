package main

import (
	"flag"
	"log"
	"net/http"
	"os"
	"path"

	"github.com/gorilla/mux"

	httpwebsocketbridge "github.com/fionera/ComputerCraftFoo/webserver-pxe/http-websocket-bridge"
	websocket_broadcaster "github.com/fionera/ComputerCraftFoo/webserver-pxe/websocket-broadcaster"
)

var addr = flag.String("addr", ":8080", "http service address")
var router = mux.NewRouter()

func main() {
	flag.Parse()

	bridge := httpwebsocketbridge.New(router)
	go bridge.Run()

	broadcaster := websocket_broadcaster.New()
	go broadcaster.Run()

	router.HandleFunc("/startup.lua", func(writer http.ResponseWriter, request *http.Request) {
		log.Println(request.URL.String())

		label := request.URL.Query().Get("label")
		script := path.Join("boot", label+".lua")

		_, err := os.Stat(script)
		if label == "" || err != nil {
			http.ServeFile(writer, request, "scripts/no_label.lua")
			return
		}

		http.ServeFile(writer, request, script)
	})

	router.HandleFunc("/init.lua", func(writer http.ResponseWriter, request *http.Request) {
		http.ServeFile(writer, request, "scripts/init.lua")
	})

	router.HandleFunc("/ws", bridge.HandleWebsocket)
	router.HandleFunc("/bc", broadcaster.HandleWebsocket)

	err := http.ListenAndServe(*addr, router)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
