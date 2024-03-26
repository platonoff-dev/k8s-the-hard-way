#!/bin/bash

sudo ./create-net.sh
sudo ./start-vm.sh

./generate-certs.sh
./distribute-certs.sh
