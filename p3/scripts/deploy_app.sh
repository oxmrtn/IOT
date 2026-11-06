#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_DIR="${SCRIPT_DIR}/../confs"

kubectl apply -f "${CONF_DIR}/application.yaml"

until kubectl get pods -n dev -l app=wil-playground 2>/dev/null | grep -q "Running"; do
    sleep 3
done
kubectl get all -n dev

sleep 2
curl -s http://localhost:8888/
