#!/bin/bash


for instance_name in loadbalancer master1 master2 master3 worker1 worker2 worker3
do
	sudo virsh destroy $instance_name
	sudo virsh undefine --remove-all-storage $instance_name
done

sudo virsh net-destroy k8s-net
sudo virsh net-undefine k8s-net

sudo rm -rf runtime
