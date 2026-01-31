#!/bin/bash
set -euo pipefail

CTX=""
MODE="sanity"
JSON_ONLY="0"

for arg in "$@"; do
  case "$arg" in
    full) MODE="full" ;;
    json) JSON_ONLY="1" ;;
    *) CTX="$arg" ;;
  esac
done

CTX_ARGS=()
[ -n "$CTX" ] && CTX_ARGS+=(--context "$CTX")

kc() { kubectl "${CTX_ARGS[@]}" "$@"; }

require_pod() {
  local name="$1"
  if ! kc get pod "$name" &>/dev/null; then
    echo "Pod $name not found; deploy fortio workload first."
    exit 1
  fi
}

require_pod fortio-client-w1
require_pod fortio-client-w2
require_pod fortio-server-w1
require_pod fortio-server-w2

kc wait --for=condition=Ready pod/fortio-client-w1 pod/fortio-client-w2 pod/fortio-server-w1 pod/fortio-server-w2 --timeout=120s >/dev/null

kc apply -k kubernetes/fortio/service >/dev/null
trap 'kc delete -k kubernetes/fortio/service --ignore-not-found' EXIT

server_w1_ip=$(kc get pod fortio-server-w1 -o jsonpath='{.status.podIP}')
server_w2_ip=$(kc get pod fortio-server-w2 -o jsonpath='{.status.podIP}')

if [ "$MODE" = "full" ]; then
  CONC=16
  DURATION=30s
  QPS=0
else
  CONC=4
  DURATION=10s
  QPS=0
fi

run_fortio() {
  local target="$1"
  local label="$2"
  local port="$3"
  if [ "$JSON_ONLY" = "1" ]; then
    kc exec fortio-client-w1 -- fortio load -a -quiet -json - -c "$CONC" -t "$DURATION" -qps "$QPS" "http://$target${port:+:$port}/"
  else
    echo "$label"
    kc exec fortio-client-w1 -- fortio load -a -quiet -c "$CONC" -t "$DURATION" -qps "$QPS" "http://$target${port:+:$port}/"
    echo
  fi
}

if [ "$JSON_ONLY" != "1" ]; then echo "Running fortio tests in $MODE mode"; fi

run_fortio "$server_w1_ip:8080" "Same-node (client-w1 -> server-w1, pod IP):" ""
run_fortio "$server_w2_ip:8080" "Cross-node (client-w1 -> server-w2, pod IP):" ""
run_fortio "fortio-service" "Service path (client-w1 -> fortio-service):" "80"
