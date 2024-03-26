#!/bin/bash

WORKDIR=$(pwd)
CERT_CONFIG=$(pwd)/config/certs
mkdir runtime/certs
cd runtime/certs

# CA
cfssl gencert -initca $CERT_CONFIG/ca-csr.json | cfssljson -bare ca

# Admin
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=$CERT_CONFIG/ca.json \
  -profile=kubernetes \
  $CERT_CONFIG/admin-csr.json | cfssljson -bare admin


# Kubelet
export DOMAIN=k8s-thw.local
for INSTANCE in worker1 worker2 worker3
do
    python $WORKDIR/helpers/insert_envs.py $CERT_CONFIG/kubelet-csr.json $INSTANCE-kubelet-csr.json

    NODE_IP=$(sudo virsh -q domifaddr $INSTANCE | awk '{print $4}' | cut -f1 -d"/")
    cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=$CERT_CONFIG/ca.json \
        -hostname=${INSTANCE}.${DOMAIN},${INSTANCE},${NODE_IP} \
        -profile=kubernetes \
        ${INSTANCE}-kubelet-csr.json | cfssljson -bare ${INSTANCE}
done

# Controller manager 
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=$CERT_CONFIG/ca.json \
  -profile=kubernetes \
  $CERT_CONFIG/controller-manager-csr.json | cfssljson -bare kube-controller-manager


# Kube proxy
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=$CERT_CONFIG/ca.json \
  -profile=kubernetes \
  $CERT_CONFIG/kube-proxy.json | cfssljson -bare kube-proxy


# Scheduler
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=$CERT_CONFIG/ca.json \
  -profile=kubernetes \
  $CERT_CONFIG/scheduler.json | cfssljson -bare kube-scheduler


# API Server
KUBERNETES_BAREMETAL_ADDRESS=192.168.31.5
KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local
for node in loadbalancer master1 master2 master3
do 
    export IP_${node}=$(sudo virsh -q domifaddr $node | awk '{print $4}' | cut -f1 -d"/")
    echo "IP_$node=$(printenv IP_$node)"
done
cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=$CERT_CONFIG/ca.json \
        -hostname=loadbalancer.${DOMAIN},10.32.0.1,${IP_loadbalancer},${IP_master1},${IP_master2},${IP_master3},${KUBERNETES_BAREMETAL_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
        -profile=kubernetes \
        $CERT_CONFIG/api-server.json | cfssljson -bare kubernetes


# Service account
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=$CERT_CONFIG/ca.json \
  -profile=kubernetes \
  $CERT_CONFIG/service-account.json | cfssljson -bare service-account
