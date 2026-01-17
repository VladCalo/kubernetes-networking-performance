#!/bin/bash
set -euo pipefail

CTX="${1:-}"
CTX_ARGS=()
if [ -n "$CTX" ]; then
  CTX_ARGS+=(--context "$CTX")
fi

# apply shared service (ClusterIP)
kubectl "${CTX_ARGS[@]}" apply -k kubernetes/shared

mapfile -t workers < <(kubectl "${CTX_ARGS[@]}" get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep worker | sort)

if [ "${#workers[@]}" -lt 2 ]; then
  echo "Need at least two worker nodes; found ${#workers[@]}"
  exit 1
fi

w1="${workers[0]}"
w2="${workers[1]}"

kubectl kustomize kubernetes/overlays/worker1 | sed "s/NODE_NAME_PLACEHOLDER/$w1/g" | kubectl "${CTX_ARGS[@]}" apply -f -
kubectl kustomize kubernetes/overlays/worker2 | sed "s/NODE_NAME_PLACEHOLDER/$w2/g" | kubectl "${CTX_ARGS[@]}" apply -f -

echo "Deployed http-echo server/clients to $w1 and $w2"
