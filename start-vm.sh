#!/bin/bash

IGNITION_CONFIG="$(pwd)/runtime/config.ign"
IMAGE="$(pwd)/runtime/fedora-coreos-39.20240225.3.0-qemu.x86_64.qcow2"
VCPUS="2"
RAM_MB="2048"
STREAM="stable"
DISK_GB="10"
NETWORK="k8s-net"
DOMAIN_NAME="k8s-thw.local"

# For x86 / aarch64,
IGNITION_DEVICE_ARG=(--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}")

mkdir runtime/disks

generate_config() {
	python helpers/insert_envs.py $SRC_PATH $DEST_PATH

	podman run \
    --rm \
    -v $(pwd):/workdir:z \
    quay.io/coreos/butane:release --pretty --strict --files-dir /workdir /workdir/runtime/config.bu > runtime/config.ign
}

start_vm() {
	sudo virt-install \
		--name="${VM_NAME}" \
		--vcpus="${VCPUS}" \
		--memory="${RAM_MB}" \
		--os-variant="fedora-coreos-$STREAM" \
		--network network=$NETWORK \
		--import \
		--graphics=none \
		--disk="path=runtime/disks/${VM_NAME}.qcow2,size=${DISK_GB},backing_store=${IMAGE}" \
		--noautoconsole \
		"${IGNITION_DEVICE_ARG[@]}"
}

# master nodes
for VM_NAME in master1 master2 master3
do	
	HOST_NAME=$VM_NAME \
	DOMAIN_NAME=$DOMAIN_NAME \
	SRC_PATH=config/nodes/master/butane.yaml \
	DEST_PATH=runtime/config.bu \
		generate_config
	
	start_vm
done

# Worker nodes
for VM_NAME in worker1 worker2 worker3
do
	HOST_NAME=$VM_NAME \
	DOMAIN_NAME=$DOMAIN_NAME \
	SRC_PATH=config/nodes/worker/butane.yaml \
	DEST_PATH=runtime/config.bu \
		generate_config
	
	start_vm
done

for (( ; ; ))
do
	master1_IP=$(sudo virsh -q domifaddr master1 | awk '{print $4}' | cut -f1 -d"/")
	master2_IP=$(sudo virsh -q domifaddr master2 | awk '{print $4}' | cut -f1 -d"/")
	master3_IP=$(sudo virsh -q domifaddr master3 | awk '{print $4}' | cut -f1 -d"/")
	count=$(($(echo $master1_IP | wc -w) + $(echo $master2_IP | wc -w) + $(echo $master3_IP | wc -w)))
	echo "Waiting for master ips - $count - $(date +'%H:%m:%S')"
	if [ $count = 3 ]
	then
		break
	fi
	sleep 1
done

# Start loadbalancer
VM_NAME=loadbalancer

master1_IP=$(sudo virsh -q domifaddr master1 | awk '{print $4}' | cut -f1 -d"/") \
master2_IP=$(sudo virsh -q domifaddr master2 | awk '{print $4}' | cut -f1 -d"/") \
master3_IP=$(sudo virsh -q domifaddr master3 | awk '{print $4}' | cut -f1 -d"/") \
DOMAIN_NAME=$DOMAIN_NAME \
	python helpers/insert_envs.py config/nodes/loadbalancer/haproxy.cfg runtime/haproxy.cfg

HOST_NAME=$VM_NAME \
DOMAIN_NAME=$DOMAIN_NAME \
SRC_PATH=config/nodes/loadbalancer/butane.yaml \
DEST_PATH=runtime/config.bu \
	generate_config

start_vm

for (( ; ; ))
do
	balancer_ip=$(sudo virsh -q domifaddr loadbalancer | awk '{print $4}' | cut -f1 -d"/")
	echo "Waiting for balancer ips - $(date +'%H:%m:%S')"
	if [ $(echo $balancer_ip | wc -w) = 1 ]
	then
		break
	fi
	sleep 1
done
