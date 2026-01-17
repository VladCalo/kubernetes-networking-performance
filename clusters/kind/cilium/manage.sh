#!/bin/bash

CLUSTER_NAME="cilium"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../common/utility.sh"

create_cluster() {
    kind create cluster --name "$CLUSTER_NAME" --config "$SCRIPT_DIR/kind-cilium.yaml"
    cilium install --context kind-cilium
    cilium status --wait --context kind-cilium
    cilium hubble enable --ui --context kind-cilium
    cilium hubble status --wait --context kind-cilium

    # go to hubble UI: cilium hubble ui --context kind-cilium
    taint_control_plane "$CLUSTER_NAME"
    load_images "$CLUSTER_NAME"
    deploy_shared "$CLUSTER_NAME"
    deploy_pods "$CLUSTER_NAME"
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
