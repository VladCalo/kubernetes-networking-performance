#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLUSTER_PATH="$ROOT_DIR/clusters/kind"
WORKLOAD_IPERF="$ROOT_DIR/workloads/iperf3/deploy.sh"
TEST_IPERF="$ROOT_DIR/test-suite/iperf/run.sh"

create_cluster() {
    local name="$1"
    case "$name" in
        calico)  bash "${CLUSTER_PATH}/calico/manage.sh" create ;;
        default) bash "${CLUSTER_PATH}/default/manage.sh" create ;;
        cilium)  bash "${CLUSTER_PATH}/cilium/manage.sh" create ;;
        *)
            echo "Unknown cluster: $name"
            exit 1
            ;;
    esac
}

delete_cluster() {
    local name="$1"
    case "$name" in
        calico)  bash "${CLUSTER_PATH}/calico/manage.sh" delete ;;
        default) bash "${CLUSTER_PATH}/default/manage.sh" delete ;;
        cilium)  bash "${CLUSTER_PATH}/cilium/manage.sh" delete ;;
    esac
}

run_suite() {
    local name="$1"
    local ctx="kind-${name}"
    local outfile="$ROOT_DIR/${name}.txt"

    echo "Deploying iperf workload to $name..."
    bash "$WORKLOAD_IPERF" "$ctx"

    echo "Running iperf test suite (full) on $name..."
    bash "$TEST_IPERF" full "$ctx" > "$outfile"
    echo "Saved results to $outfile"
}

for cluster in cilium; do
    echo "=== Cluster: $cluster ==="
    create_cluster "$cluster"
    run_suite "$cluster"
    delete_cluster "$cluster"
done
