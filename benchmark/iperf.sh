#!/bin/bash

set -euo pipefail
CLUSTER_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/clusters/kind"

create_cluster() {
    case "$1" in
        calico)
            echo "Creating calico cluster..."
            bash "${CLUSTER_PATH}/calico/manage.sh" create
            ;;
        default)
            echo "Creating default cluster..."
            bash "${CLUSTER_PATH}/default/manage.sh" create
            ;;
        cilium)
            echo "Creating cilium cluster..."
            bash "${CLUSTER_PATH}/cilium/manage.sh" create
            ;;
        *)
            echo "Unknown option: $1"
            echo "Valid options: calico | default | cilium"
            exit 1
            ;;
    esac
}

create_cluster calico
