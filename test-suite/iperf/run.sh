#!/bin/bash
set -euo pipefail

MODE="${1:-sanity}"
CTX="${2:-}"

case "$MODE" in
  sanity|full) ;;
  *)
    CTX="$MODE"
    MODE="sanity"
    ;;
esac

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
echo "Running iperf tests in $MODE mode"

server_w1_ip=$(kc get pod iperf-server-w1 -o jsonpath='{.status.podIP}')
server_w2_ip=$(kc get pod iperf-server-w2 -o jsonpath='{.status.podIP}')

echo "Same-node (client-w1 -> server-w1, pod IP):"
if [ "$MODE" = "full" ]; then
  kc exec iperf-client-w1 -- iperf3 -c "$server_w1_ip" -P 4 -t 30 -i 5
else
  kc exec iperf-client-w1 -- iperf3 -c "$server_w1_ip" -P 1 -t 3 -i 1
fi
echo

echo "Cross-node (client-w1 -> server-w2, pod IP):"
if [ "$MODE" = "full" ]; then
  kc exec iperf-client-w1 -- iperf3 -c "$server_w2_ip" -P 4 -t 30 -i 5
else
  kc exec iperf-client-w1 -- iperf3 -c "$server_w2_ip" -P 1 -t 3 -i 1
fi
echo

if kc get svc iperf-service &>/dev/null; then
  echo "Service path (client-w1 -> iperf-service):"
  if [ "$MODE" = "full" ]; then
    kc exec iperf-client-w1 -- iperf3 -c iperf-service -p 5201 -P 4 -t 30 -i 5
  else
    kc exec iperf-client-w1 -- iperf3 -c iperf-service -p 5201 -P 1 -t 3 -i 1
  fi
  echo
fi
