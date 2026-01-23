#!/bin/bash

CLUSTER_NAME="cilium"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../common/utility.sh"

create_cluster() {
    kind create cluster --name "$CLUSTER_NAME" --config "$SCRIPT_DIR/kind-cilium.yaml"
    cilium install --context kind-cilium
    kubectl --context kind-cilium -n kube-system wait --for=condition=Ready pod -l k8s-app=cilium --timeout=300s
    cilium status --context kind-cilium || true
    cilium hubble enable --ui --context kind-cilium || true
    cilium hubble status --context kind-cilium || true

    # go to hubble UI: cilium hubble ui --context kind-cilium
    taint_control_plane "$CLUSTER_NAME"
    load_images "$CLUSTER_NAME"
}

case "$1" in
  create)
    create_cluster
    ;;
  delete)
    kind delete cluster --name "$CLUSTER_NAME"
    ;;
  *)
    echo "Usage: $0 {create|delete}"
    exit 1
    ;;
esac


