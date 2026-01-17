#!/bin/bash
set -euo pipefail

UTILITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$UTILITY_DIR/../../../kubernetes"

taint_control_plane() {
    local cluster_name="$1"
    local context="kind-${cluster_name}"
    local node="${cluster_name}-control-plane"
    
    echo "Tainting control-plane node: $node"
    kubectl --context "$context" taint nodes "$node" node-role.kubernetes.io/control-plane:NoSchedule --overwrite
}

load_images() {
    local cluster_name="$1"

    echo "Loading images into cluster: $cluster_name"
    kind load docker-image http-echo:latest --name "$cluster_name"
    kind load docker-image curl-client:latest --name "$cluster_name"
}
