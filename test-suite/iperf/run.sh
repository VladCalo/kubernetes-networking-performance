#!/bin/bash
set -euo pipefail

CTX=""
MODE="sanity"
JSON_ONLY="0"

for arg in "$@"; do
  case "$arg" in
    full) MODE="full" ;;
    json) JSON_ONLY="1" ;;
    *)    CTX="$arg" ;;
  esac
done

CTX_ARGS=()
[ -n "$CTX" ] && CTX_ARGS+=(--context "$CTX")

kc() {
  kubectl "${CTX_ARGS[@]}" "$@"
}

require_pod() {
  local name="$1"
  if ! kc get pod "$name" &>/dev/null; then
    echo "Pod $name not found; deploy iperf workload first."
    exit 1
  fi
}

require_pod iperf-client-w1
require_pod iperf-client-w2
require_pod iperf-server-w1
require_pod iperf-server-w2

kc wait --for=condition=Ready pod/iperf-client-w1 pod/iperf-client-w2 pod/iperf-server-w1 pod/iperf-server-w2 --timeout=60s
if [ "$JSON_ONLY" != "1" ]; then
  echo "Running iperf tests in $MODE mode"
fi

server_w1_ip=$(kc get pod iperf-server-w1 -o jsonpath='{.status.podIP}')
server_w2_ip=$(kc get pod iperf-server-w2 -o jsonpath='{.status.podIP}')

if [ "$MODE" = "full" ]; then
  PARALLEL=4
  DURATION=30
  INTERVAL=5
else
  PARALLEL=1
  DURATION=3
  INTERVAL=1
fi

run_iperf() {
  local target="$1"
  local port="$2"
  if [ "$JSON_ONLY" = "1" ]; then
    kc exec iperf-client-w1 -- iperf3 -c "$target" ${port:+-p "$port"} -P "$PARALLEL" -t "$DURATION" -i "$INTERVAL" -J
  else
    kc exec iperf-client-w1 -- iperf3 -c "$target" ${port:+-p "$port"} -P "$PARALLEL" -t "$DURATION" -i "$INTERVAL"
  fi
}

run_case() {
  local label="$1"
  local target="$2"
  local port="$3"
  if [ "$JSON_ONLY" != "1" ]; then echo "$label"; fi
  run_iperf "$target" "$port"
  if [ "$JSON_ONLY" != "1" ]; then echo; fi
}

run_case "Same-node (client-w1 -> server-w1, pod IP):" "$server_w1_ip" ""
run_case "Cross-node (client-w1 -> server-w2, pod IP):" "$server_w2_ip" ""

if kc get svc iperf-service &>/dev/null; then
  run_case "Service path (client-w1 -> iperf-service):" iperf-service 5201
fi
