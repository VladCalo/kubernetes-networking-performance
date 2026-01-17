#!/bin/bash
set -euo pipefail

CLUSTER_NAME="default"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../common/utility.sh"

case "$1" in
  create)
    kind create cluster --name "$CLUSTER_NAME" --config "$SCRIPT_DIR/kind-default.yaml"
    taint_control_plane "$CLUSTER_NAME"
    load_images "$CLUSTER_NAME"
    #deploy_shared "$CLUSTER_NAME"
    deploy_pods "$CLUSTER_NAME"
    ;;
  delete)
    kind delete cluster --name "$CLUSTER_NAME"
    ;;
  *)
    echo "Usage: $0 {create|delete}"
    exit 1
    ;;
esac
