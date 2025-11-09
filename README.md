# heezy-k8s
Application deployments for MicroK8s cluster

## Overview
Application manifests for deploying services to 5-node MicroK8s cluster. Infrastructure setup handled by [ansible-heezy](https://github.com/tnielsen2/ansible-heezy).

## Architecture
- **Cluster**: MicroK8s 1.32.9 on Nebula hosts (192.168.1.15-19)
- **Storage**: Rook-Ceph (managed by ansible-heezy)
- **Registry**: AWS ECR (025066240222.dkr.ecr.us-east-2.amazonaws.com)
- **Secrets**: AWS Secrets Manager via External Secrets Operator
- **Ingress**: MicroK8s nginx-ingress + Cloudflare Tunnel for ZTNA
- **CI/CD**: GitHub Actions with self-hosted runner
- **Monitoring**: Prometheus/LGTM stack

## Repository Structure
```
heezy-k8s/
├── base/                    # Shared resources
│   ├── namespace.yaml
│   └── cloudflare-tunnel.yaml
├── apps/                    # Application manifests
│   ├── about-website/
│   └── _template/          # Template for new services
└── .github/workflows/       # CI/CD pipelines
```

## Prerequisites (Managed by ansible-heezy)
- ✅ MicroK8s cluster with DNS, ingress, metrics-server, rook-ceph
- ✅ External Secrets Operator installed
- ✅ `aws-secrets-manager` SecretStore in default namespace
- ✅ `ecr-credentials` secret for pulling images
- ✅ `rook-ceph-block` StorageClass (default)
- ✅ GitHub runner with kubectl access

## Quick Start

### 1. Store Cloudflare Credentials in AWS
```bash
aws secretsmanager create-secret \
  --name "production/heezy/cloudflare-tunnel" \
  --secret-string file://cloudflare-credentials.json \
  --region us-east-2
```

### 2. Update Cloudflare Tunnel ID
Edit `base/cloudflare-tunnel.yaml` and replace `YOUR_TUNNEL_ID`.

### 3. Deploy
```bash
# Deploy base resources
kubectl apply -k base/
kubectl apply -f base/cloudflare-tunnel.yaml

# Deploy about-website
kubectl apply -k apps/about-website/
```

Or push to `main` branch - GitHub Actions will auto-deploy.

## Services
- ✅ about-website (about.trentnielsen.me)
- ⏳ sonarr, radarr, overseerr, tautulli, emulatorjs, sabnzbd, nzbhydra, ombi, pihole

## Adding New Services

### 1. Create AWS Secret
```bash
aws secretsmanager create-secret \
  --name "production/heezy/my-app" \
  --secret-string '{"API_KEY":"xxx"}' \
  --region us-east-2
```

### 2. Copy Template
```bash
cp -r apps/_template apps/my-app
cd apps/my-app
```

### 3. Update Manifests
Replace placeholders:
- `APP_NAME` → `my-app`
- `IMAGE_NAME:TAG` → `linuxserver/my-app:latest`
- `PORT` → service port

### 4. Create ExternalSecret (if needed)
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secrets
  namespace: heezy
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: my-app-secrets
  dataFrom:
  - extract:
      key: production/heezy/my-app
```

### 5. Deploy
```bash
kubectl apply -k apps/my-app/
```

### 6. Update Cloudflare Tunnel
Add to `base/cloudflare-tunnel.yaml`:
```yaml
- hostname: my-app.trentnielsen.me
  service: http://my-app.heezy.svc.cluster.local:PORT
```

## Logging with Prometheus/LGTM

Your pods automatically send logs to Loki. Add labels for better filtering:

```yaml
metadata:
  labels:
    app: my-app
    component: backend
```

View logs in Grafana:
```
{namespace="heezy", app="about-website"}
```

## Monitoring

Pods are auto-discovered by Prometheus if they expose metrics. Add annotations:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
```

## Troubleshooting

### Pod won't start
```bash
kubectl describe pod <pod-name> -n heezy
kubectl logs <pod-name> -n heezy
```

### Secret not syncing
```bash
kubectl describe externalsecret <name> -n heezy
kubectl logs -n external-secrets deployment/external-secrets
```

### Image pull failure
```bash
# Verify ECR secret exists (managed by ansible-heezy)
kubectl get secret ecr-credentials -n heezy

# Check if ansible-heezy ECR refresh ran recently
```

### Service not accessible
```bash
kubectl get ingress -n heezy
kubectl get svc -n heezy
kubectl logs -n heezy -l app=cloudflared
```

## Domain
All services accessible via `*.trentnielsen.me` through Cloudflare Tunnel
