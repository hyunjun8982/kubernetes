#!/bin/bash

kubectl delete -f yaml/webhook-configuration.yaml
kubectl delete -f yaml/deploy.yaml
kubectl delete secret opa-server -nopa
kubectl delete ns opa