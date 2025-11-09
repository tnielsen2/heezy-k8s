#!/bin/bash
set -e

echo "Testing about-website deployment..."

# Deploy manifests
echo "Deploying Kubernetes manifests..."
kubectl apply -k apps/about-website/

# Wait for deployment
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/about-website -n heezy --timeout=300s

# Copy files
echo "Copying website files..."
./apps/about-website/deploy-files.sh

echo "Deployment test complete!"