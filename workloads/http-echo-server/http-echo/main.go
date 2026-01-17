package main

import (
	"fmt"
	"net"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
	host, port, _ := net.SplitHostPort(r.RemoteAddr)

	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprintf(w, "Hello, IP: %s, Port: %s\n", host, port)
	fmt.Fprintf(w, "I'm node %s\n", os.Getenv("NODE_NAME"))
	fmt.Printf("Request received - IP: %s, Port: %s\n", host, port)
}

func main() {
	fmt.Println("Server is running on port 8080...")
	http.HandleFunc("/", handler)
	http.ListenAndServe(":8080", nil)
}
