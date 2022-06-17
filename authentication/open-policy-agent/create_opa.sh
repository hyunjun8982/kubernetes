#!/bin/bash

kubectl create ns opa

# Self-signed 인증서 생성
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -days 100000 -out ca.crt -subj "/CN=admission_ca"  # 이것은 Certificate Authority의 CN입니다.

# Server Certificate을 만들기 위한 설정 파일을 생성합니다. 여기서 CN이 webhook.default.svc인 것을 확인할 수 있습니다.
cat >server.conf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
prompt = no
[req_distinguished_name]
CN = webhook.default.svc
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = webhook.default.svc
EOF

openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -config server.conf
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 100000 -extensions v3_req -extfile server.conf

# 인증서 secret 저장
kubectl create secret tls opa-server --cert=server.crt --key=server.key -nopa

# deployment 배포 및 네임스페이스 라벨링
kubectl apply -f yaml/deploy.yaml
kubectl label ns kube-system openpolicyagent.org/webhook=ignore
kubectl label ns opa openpolicyagent.org/webhook=ignore

# main.rego => configmap
kubectl create cm main-repgo --from-file src/main.rego -n opa

# ValidatingWebhookConfiguration 반영
kubectl apply -f yaml/webhook-conifg.yaml

# Test (Pod is not allowed to be created by kubernetes-admin)
kubectl run mynginx --image nginx --restart Never