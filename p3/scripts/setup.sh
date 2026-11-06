#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="iot-cluster"

if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
    k3d cluster create "$CLUSTER_NAME" \
        --port "8888:8888@loadbalancer" \
        --port "8080:30080@server:0" \
        --wait
fi

until kubectl get nodes &>/dev/null; do
    sleep 2
done

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data": {"timeout.reconciliation": "30s"}}'

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"name": "https", "port": 443, "targetPort": 8080, "nodePort": 30080}]}}'

kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

until kubectl -n argocd get secret argocd-initial-admin-secret &>/dev/null; do
    sleep 2
done
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "url: https://localhost:8080"
echo "mdp: ${ARGOCD_PASSWORD}"
