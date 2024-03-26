#!/bin/bash

mkdir runtime

sudo ./create-net.sh
sudo ./start-vm.sh

./generate-certs.sh
./distribute-certs.sh

./generate-kubeconfigs.sh
./distribute-kubeconfigs.sh

./generate-data-encryption-key.sh
