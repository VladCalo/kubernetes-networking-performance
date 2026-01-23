#!/bin/bash

CLUSTER_NAME="calico"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../common/utility.sh"

create_cluster() {
    kind create cluster --name "$CLUSTER_NAME" --config "$SCRIPT_DIR/kind-calico.yaml"
    kubectl --context kind-calico apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
    kubectl --context kind-calico -n kube-system set env ds/calico-node FELIX_BPFENABLED=true FELIX_BPFKUBEPROXYIPTABLESCLEANUPENABLED=true
    kubectl --context kind-calico -n kube-system rollout status ds/calico-node --timeout=300s
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
