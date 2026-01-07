package main

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
)

type Response struct {
	Message string `json:"message"`
	IP string `json:"ip"`
	Port string `json:"port"`
}

func handler(w http.ResponseWriter, r *http.Request) {
	host, port, _ := net.SplitHostPort(r.RemoteAddr)

	resp := Response{
		Message: "Hello!",
		IP: host,
		Port: port,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func main() {
	fmt.Println("Server is running on port 8080")
	http.HandleFunc("/", handler)
	http.ListenAndServe(":8080", nil)
}

