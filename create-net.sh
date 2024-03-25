#!/bin/bash

sudo virsh net-define config/network.xml
sudo virsh net-autostart k8s-net
sudo virsh net-start k8s-net
