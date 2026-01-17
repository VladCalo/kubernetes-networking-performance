#!/bin/bash
set -euo pipefail

CTX="${1:-}"
CTX_ARGS=()
if [ -n "$CTX" ]; then
  CTX_ARGS+=(--context "$CTX")
fi

kc() {
  kubectl "${CTX_ARGS[@]}" "$@"
}

require_pod() {
  local name="$1"
  if ! kc get pod "$name" &>/dev/null; then
    echo "Pod $name not found; deploy echo workload first."
    exit 1
  fi
}

require_pod client-w1
require_pod client-w2
require_pod echo-server-w1
require_pod echo-server-w2

server_w1_ip=$(kc get pod echo-server-w1 -o jsonpath='{.status.podIP}')
server_w2_ip=$(kc get pod echo-server-w2 -o jsonpath='{.status.podIP}')

echo "Service from client-w1:"
kc exec client-w1 -- curl -sS http://echo-service
echo

echo "Service from client-w2:"
kc exec client-w2 -- curl -sS http://echo-service
echo

echo "Direct pod IP (client-w1 -> echo-server-w2):"
kc exec client-w1 -- curl -sS "http://$server_w2_ip:8080"
echo

echo "Direct pod IP (client-w2 -> echo-server-w1):"
kc exec client-w2 -- curl -sS "http://$server_w1_ip:8080"
echo
