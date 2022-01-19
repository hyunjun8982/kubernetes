# 0. Define variables
IMAGE = admission-controller-webhook-daemon:latest
NAMESPACE = mutate-server-test

# 1.1. Load docker base image
docker load -i image/python-3.8-slim.tar

# 1.2. Build docker image
docker build -t $IMAGE -f image/Dockerfile .

# 2. Create namespace for demo
kubectl create namespace $NAMESPACE

# 3.1. Create key pair
# Service DNS discovery name is "mutate-server-svc.{{NAMESPACE}}.svc" 
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=Acme Root CA" -out ca.crt

openssl req -newkey rsa:2048 -nodes -keyout server.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=mutate-server-svc.$NAMESPACE.svc" -out server.csr
printf "subjectAltName=DNS:mutate-server-svc.$NAMESPACE.svc" > tmp-ext-file
openssl x509 -req -extfile tmp-ext-file -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

# 3.2. Create TLS secret for service
kubectl create secret tls webhook-certs --cert "server.crt" --key "server.key" -n $NAMESPACE

# 4. Create Mutator Server (Flask) as a Deployment and Service
cat yaml/webhook-mutate-deploy.yaml | sed "s/{{NAMESPACE}}/$NAMESPACE/g" | kubectl apply -n $NAMESPACE -f -

# 5. Register Mutator Server (Flask) as a Mutate Webhook to Kubernetes
export CA_PEM_BASE64="$(openssl base64 -A <"ca.crt")"
cat yaml/mutate-webhook-conf.yaml | sed "s/{{CA_PEM_BASE64}}/$CA_PEM_BASE64/g" | sed "s/{{NAMESPACE}}/$NAMESPACE/g" | kubectl apply -n $NAMESPACE -f -

# 6. Clean secret files
rm -rf server.* ca.* tmp-ext-file