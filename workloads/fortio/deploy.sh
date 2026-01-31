#!/bin/bash
set -euo pipefail

CTX="${1:-}"
CTX_ARGS=()
[ -n "$CTX" ] && CTX_ARGS+=(--context "$CTX")

echo "Waiting for Cilium (if present)..."
kubectl "${CTX_ARGS[@]}" -n kube-system wait --for=condition=Ready pod -l k8s-app=cilium --timeout=180s >/dev/null 2>&1 || true

mapfile -t workers < <(kubectl "${CTX_ARGS[@]}" get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep worker | sort)
if [ "${#workers[@]}" -lt 2 ]; then
  echo "Need at least two worker nodes; found ${#workers[@]}"
  exit 1
fi

w1="${workers[0]}"
w2="${workers[1]}"

kubectl kustomize kubernetes/fortio/overlays/worker1 | sed "s/NODE_NAME_PLACEHOLDER/$w1/g" | kubectl "${CTX_ARGS[@]}" apply -f -
kubectl kustomize kubernetes/fortio/overlays/worker2 | sed "s/NODE_NAME_PLACEHOLDER/$w2/g" | kubectl "${CTX_ARGS[@]}" apply -f -
