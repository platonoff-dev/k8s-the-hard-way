#!/bin/bash

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)


cat > runtime/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

for node in master1 master2 master3; do 
    NODE_IP=$(sudo virsh -q domifaddr $node | awk '{print $4}' | cut -f1 -d"/")
	echo "Copying runtime/encryption-config.yaml to root@$NODE_IP"
	scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null runtime/encryption-config.yaml root@${NODE_IP}:~
  done