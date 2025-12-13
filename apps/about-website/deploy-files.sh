#!/bin/bash
# Script to copy website files to SWAG container after deployment

SERVICE="about-website"

echo "Waiting for $SERVICE pod to be ready..."
kubectl wait --for=condition=ready pod -l app=$SERVICE -n heezy --timeout=300s

POD_NAME=$(kubectl get pods -n heezy -l app=$SERVICE -o jsonpath='{.items[0].metadata.name}')

echo "Copying website files to pod: $POD_NAME"
kubectl cp src/. heezy/$POD_NAME:/config/www/ -c swag

echo "Website files deployed successfully!"
