#!/bin/bash

CERTS=$(pwd)/runtime/certs
KUBERNETES_PUBLIC_ADDRESS=$(sudo virsh -q domifaddr loadbalancer | awk '{print $4}' | cut -f1 -d"/")
DOMAIN=k8s-thw.local

mkdir runtime/kubeconfigs
cd runtime/kubeconfigs


generate_config() {
    kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=$CERTS/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=$OUT_PATH

  kubectl config set-credentials $USER \
    --client-certificate=$CERT_PATH \
    --client-key=$CERT_KEY_PATH \
    --embed-certs=true \
    --kubeconfig=$OUT_PATH

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=$USER \
    --kubeconfig=$OUT_PATH

  kubectl config use-context default --kubeconfig=$OUT_PATH
}

# worker nodes kubelet
for instance in worker1 worker2 worker3; do
    OUT_PATH=${instance}.kubeconfig
    USER=system:node:${instance}.${DOMAIN}
    CERT_PATH=$CERTS/${instance}.pem
    CERT_KEY_PATH=$CERTS/${instance}.pem
    generate_config
done

# kube proxy
OUT_PATH=kube-proxy.kubeconfig
USER=system:kube-proxy
CERT_PATH=$CERTS/kube-proxy.pem
CERT_KEY_PATH=$CERTS/kube-proxy-key.pem
generate_config

# controller manager
OUT_PATH=kube-controller-manager.kubeconfig
USER=system:kube-controller-manager
CERT_PATH=$CERTS/kube-controller-manager.pem
CERT_KEY_PATH=$CERTS/kube-controller-manager-key.pem
generate_config

# scheduler
OUT_PATH=kube-scheduler.kubeconfig
USER=system:kube-scheduler
CERT_PATH=$CERTS/kube-scheduler.pem
CERT_KEY_PATH=$CERTS/kube-scheduler-key.pem
generate_config

# admin
OUT_PATH=admin.kubeconfig
USER=admin
CERT_PATH=$CERTS/admin.pem
CERT_KEY_PATH=$CERTS/admin-key.pem
generate_config
