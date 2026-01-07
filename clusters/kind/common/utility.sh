#!/bin/bash

taint_control_plane() {
    local cluster_name="$1"
    local context="kind-${cluster_name}"
    local node="${cluster_name}-control-plane"
    
    echo "Tainting control-plane node: $node"
    kubectl --context "$context" taint nodes "$node" node-role.kubernetes.io/control-plane:NoSchedule --overwrite
}
