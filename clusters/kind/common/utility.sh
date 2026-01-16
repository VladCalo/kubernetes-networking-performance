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

deploy_shared() {
    local cluster_name="$1"
    local context="kind-${cluster_name}"

    echo "Deploying shared resources"
    kubectl --context "$context" apply -k "$K8S_DIR/shared"
}

deploy_pods() {
    local cluster_name="$1"
    local context="kind-${cluster_name}"
    
    local workers=($(kubectl --context "$context" get nodes -o name | grep worker | cut -d/ -f2))
    
    echo "Deploying pods to workers: ${workers[*]}"
    
    for i in "${!workers[@]}"; do
        local node="${workers[$i]}"
        local overlay="worker$((i+1))"
        
        echo "Deploying to $node using overlay $overlay..."
        
        kubectl kustomize "$K8S_DIR/overlays/$overlay" | \
            sed "s/NODE_NAME_PLACEHOLDER/$node/g" | \
            kubectl --context "$context" apply -f -
    done
    
    echo "Waiting for pods to be ready..."
    kubectl --context "$context" wait --for=condition=Ready pod -l app=http-echo --timeout=60s
    kubectl --context "$context" wait --for=condition=Ready pod -l app=curl-client --timeout=60s
    
    echo "Pods deployed:"
    kubectl --context "$context" get pods -o wide
}
