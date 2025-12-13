# Docker Compose to K8s Migration Guide

## Prerequisites

1. NFS storage class `nfs-media` configured (pointing to 192.168.1.200)
2. ECR credentials secret `ecr-credentials` in heezy namespace
3. AWS CLI configured with ECR access

## Step 1: Deploy Base NFS PVCs

```bash
kubectl apply -k base/
```

Verify NFS PVCs are bound:
```bash
kubectl get pvc -n heezy | grep nfs
```

## Step 2: Migrate SWAG (about-website)

```bash
cd apps/about-website

# Copy config files from docker-compose
cp -r /path/to/docker-compose-usenet/media-services/swag ./swag-config

# Build and push to ECR
chmod +x build-and-push.sh
./build-and-push.sh

# Deploy
kubectl apply -k .
```

## Step 3: Migrate Other Services

For each service (sonarr, radarr, overseerr, tautulli, emulatorjs, sabnzbd, nzbhydra, ombi):

```bash
# Create app directory
cp -r apps/_template-with-config apps/SERVICE_NAME
cd apps/SERVICE_NAME

# Copy config from docker-compose
cp -r /path/to/docker-compose-usenet/CONFIG/SERVICE_NAME ./config

# Update placeholders
sed -i '' 's/APP_NAME/SERVICE_NAME/g' *.yaml *.sh Dockerfile
sed -i '' 's/PORT/SERVICE_PORT/g' *.yaml

# Adjust volumes in deployment.yaml (remove unused mounts)

# Build and push
chmod +x build-and-push.sh
./build-and-push.sh

# Deploy
kubectl apply -k .
```

## Service Ports Reference

- sonarr: 8989
- radarr: 7878
- overseerr: 5055
- tautulli: 8181
- emulatorjs: 3000
- sabnzbd: 8080
- nzbhydra: 5076
- ombi: 3579
- pihole: 80

## Step 4: Update Cloudflare Tunnel

Add each service to `base/cloudflare-tunnel.yaml`:

```yaml
- hostname: SERVICE_NAME.trentnielsen.me
  service: http://SERVICE_NAME.heezy.svc.cluster.local:PORT
```

Apply:
```bash
kubectl apply -f base/cloudflare-tunnel.yaml
```

## Troubleshooting

### Image pull errors
```bash
kubectl get secret ecr-credentials -n heezy
```

### Config not persisting
Check if PVC is bound:
```bash
kubectl get pvc -n heezy
kubectl describe pvc SERVICE_NAME-config -n heezy
```

### NFS mount issues
```bash
kubectl describe pvc nfs-movies -n heezy
kubectl logs -n heezy POD_NAME
```
