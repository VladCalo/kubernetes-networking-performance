#!/bin/bash

CONTEXT="$1"
# Contexts: kind-cilium, kind-calico, kind-default

if [ -z "$CONTEXT" ]; then
    echo "Usage: $0 <context>"
    exit 1
fi

kubectl --context $CONTEXT create deployment nginx --image=nginx
kubectl --context $CONTEXT scale deployment nginx --replicas=3
kubectl --context $CONTEXT rollout status deployment/nginx
kubectl --context $CONTEXT get pods -o wide