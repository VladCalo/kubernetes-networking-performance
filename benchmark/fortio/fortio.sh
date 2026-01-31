#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLUSTER_PATH="$ROOT_DIR/clusters/kind"
WORKLOAD="$ROOT_DIR/workloads/fortio/deploy.sh"
TEST="$ROOT_DIR/test-suite/fortio/run.sh"
RESULT_DIR="$ROOT_DIR/benchmark/fortio/results"

mkdir -p "$RESULT_DIR"

create_cluster() {
  case "$1" in
    calico)  bash "$CLUSTER_PATH/calico/manage.sh" create ;;
    default) bash "$CLUSTER_PATH/default/manage.sh" create ;;
    cilium)  bash "$CLUSTER_PATH/cilium/manage.sh" create ;;
    *) echo "Unknown cluster $1"; exit 1 ;;
  esac
}

delete_cluster() {
  case "$1" in
    calico)  bash "$CLUSTER_PATH/calico/manage.sh" delete ;;
    default) bash "$CLUSTER_PATH/default/manage.sh" delete ;;
    cilium)  bash "$CLUSTER_PATH/cilium/manage.sh" delete ;;
  esac
}

run_suite() {
  local name="$1"
  local ctx="kind-${name}"
  local outfile="$RESULT_DIR/${name}.txt"

  echo "Deploying fortio workload to $name..."
  bash "$WORKLOAD" "$ctx"

  echo "Running fortio test suite (full) on $name..."
  bash "$TEST" full "$ctx" > "$outfile"
  echo "Saved results to $outfile"
}

for cluster in default calico cilium; do
  echo "=== Cluster: $cluster ==="
  create_cluster "$cluster"
  run_suite "$cluster"
  delete_cluster "$cluster"
done
