#!/bin/bash

cd runtime/kubeconfigs


for node in worker1 worker2 worker3; do
    NODE_IP=$(sudo virsh -q domifaddr $node | awk '{print $4}' | cut -f1 -d"/")
  	for key in ${node}.kubeconfig kube-proxy.kubeconfig; do 
		echo "Copying $key to root@$NODE_IP"
		scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${key} root@${NODE_IP}:~
	done
done


for node in master1 master2 master3; do
    NODE_IP=$(sudo virsh -q domifaddr $node | awk '{print $4}' | cut -f1 -d"/")
  	for key in admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig; do 
		echo "Copying $key to root@$NODE_IP"
		scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${key} root@${NODE_IP}:~
    done 
done

