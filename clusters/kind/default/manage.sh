#!/bin/bash

CLUSTER_NAME="default"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$1" in
  create)
    kind create cluster --name "$CLUSTER_NAME" --config "$SCRIPT_DIR/kind-default.yaml"
    ;;
  delete)
    kind delete cluster --name "$CLUSTER_NAME"
    ;;
  *)
    echo "Usage: $0 {create|delete}"
    exit 1
    ;;
esac
