package main

import (
	"encoding/base64"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"github.com/tailscale/hujson"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		log.Println("/")
		io.WriteString(w, "Hello World")
	})

	http.HandleFunc("/format", handle_hujson)
	log.Println("Started")

	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Println("Server Failed to Start")
	}

}

func handle_hujson(w http.ResponseWriter, req *http.Request) {
	// handle_hujson handles the HuJSON from the request, formats and sends back a HuJSON response
	log.Println("/format")
	body, err := ioutil.ReadAll(req.Body)
	if err != nil {
		log.Println("Reading Body failed")
	}
	b64E, err := base64.StdEncoding.DecodeString(string(body))
	if err != nil {
		log.Println("B64 decode failed", err)
	}

	formatted, err := hujson.Format(b64E)
	if err != nil {
		log.Println("Formatter Failed")
	}

	io.WriteString(w, string(formatted))

}
