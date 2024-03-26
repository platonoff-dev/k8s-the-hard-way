#!/bin/bash

cd runtime/certs

for node in worker1 worker2 worker3; do
    NODE_IP=$(sudo virsh -q domifaddr $node | awk '{print $4}' | cut -f1 -d"/")
  	for key in ${node}-key.pem ${node}.pem kube-proxy-key.pem kube-proxy.pem ca.pem ; do 
		echo "Copying $key to root@$NODE_IP"
		scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${key} root@${NODE_IP}:~
	done
done


for node in master1 master2 master3; do
    NODE_IP=$(sudo virsh -q domifaddr $node | awk '{print $4}' | cut -f1 -d"/")
  	for key in ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem; do 
		echo "Copying $key to root@$NODE_IP"
		scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${key} root@${NODE_IP}:~
    done 
done
