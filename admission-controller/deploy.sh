IMAGE = admission-controller-webhook-daemon:latest
NAMESPACE = mutate-server-test

#1. Build docker image
docker build -t ${IMAGE} image/

# 1. Create namespace for demo
kubectl create namespace $NAMESPACE

# 2.1 Create key pair
# Service DNS discovery name is "mutate-server-svc.{{NAMESPACE}}.svc" 
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=Acme Root CA" -out ca.crt

openssl req -newkey rsa:2048 -nodes -keyout server.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=mutate-server-svc.$NAMESPACE.svc" -out server.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:mutate-server-svc.$NAMESPACE.svc") -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

# 2.2 Create TLS secret for service
kubectl create secret tls webhook-certs --cert "server.crt" --key "server.key" -n $NAMESPACE

# 3. Create Mutator Server (Flask) as a Deployment and Service
cat yaml/webhook-mutate-deploy.yaml | sed "s/{{NAMESPACE}}/$NAMESPACE/g" | kubectl apply -n $NAMESPACE -f -

# 4. Register Mutator Server (Flask) as a Mutate Webhook to Kubernetes
export CA_PEM_BASE64="$(openssl base64 -A <"ca.crt")"
cat yaml/mutate-webhook-conf.yaml | sed "s/{{CA_PEM_BASE64}}/$CA_PEM_BASE64/g" | kubectl apply -n $NAMESPACE -f -

# 5. Clean secret files
rm -rf webhook-server-tls.* ca.*