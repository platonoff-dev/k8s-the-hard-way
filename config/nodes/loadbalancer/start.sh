#!bin/bash


podman run \
    -d \
    --name haproxy \
    -p 6443:6443 -p 9090:9090 \
    -v /etc/haproxy:/usr/local/etc/haproxy \
    --sysctl net.ipv4.ip_unprivileged_port_start=0 \
    docker.io/library/haproxy:2.9
