# Setup Guide

## Prerequisites
Ensure [ansible-heezy](https://github.com/tnielsen2/ansible-heezy) has been run to configure:
- MicroK8s cluster with required addons
- External Secrets Operator
- ECR authentication
- Storage classes
- GitHub runner access

## Initial Setup

### 1. Store Cloudflare Tunnel Credentials
```bash
aws secretsmanager create-secret \
  --name "production/heezy/cloudflare-tunnel" \
  --secret-string file://cloudflare-credentials.json \
  --region us-east-2
```

The JSON should contain your Cloudflare tunnel credentials.

### 2. Configure Cloudflare Tunnel
Edit `base/cloudflare-tunnel.yaml`:
- Replace `YOUR_TUNNEL_ID` with your actual tunnel ID
- Update ingress rules for your services

### 3. Deploy Base Resources
```bash
kubectl apply -k base/
kubectl apply -f base/cloudflare-tunnel.yaml
```

### 4. Deploy About Website
```bash
# Replace apps/about-website/index.html with your actual site
kubectl apply -k apps/about-website/
```

Or push to GitHub - workflow will auto-deploy.

## Verify Deployment

```bash
# Check namespace
kubectl get ns heezy

# Check pods
kubectl get pods -n heezy

# Check secrets synced from AWS
kubectl get externalsecret -n heezy
kubectl get secret cloudflared-credentials -n heezy

# Check services
kubectl get svc -n heezy

# Check ingress
kubectl get ingress -n heezy

# View logs
kubectl logs -n heezy -l app=about-website
kubectl logs -n heezy -l app=cloudflared
```

## GitHub Actions Setup

Your self-hosted runner (configured by ansible-heezy) already has:
- kubectl with cluster access
- AWS CLI configured
- Docker installed

No secrets needed in GitHub repository.

## Adding More Services

See [MIGRATION.md](MIGRATION.md) for migrating Docker Compose services.

### Quick Example: Sonarr
```bash
# Copy template
cp -r apps/_template apps/sonarr

# Edit files
cd apps/sonarr
sed -i '' 's/APP_NAME/sonarr/g' *.yaml
sed -i '' 's|IMAGE_NAME:TAG|linuxserver/sonarr:latest|g' deployment.yaml
sed -i '' 's/PORT/8989/g' *.yaml

# Deploy
kubectl apply -k .

# Add to Cloudflare tunnel
# Edit base/cloudflare-tunnel.yaml and add:
# - hostname: sonarr.trentnielsen.me
#   service: http://sonarr.heezy.svc.cluster.local:8989

kubectl apply -f base/cloudflare-tunnel.yaml
kubectl rollout restart deployment/cloudflared -n heezy
```

## Monitoring & Logging

### View Logs in Grafana
Your Prometheus/LGTM stack automatically collects logs from all pods in `heezy` namespace.

Access Grafana and query:
```
{namespace="heezy", app="about-website"}
```

### View Metrics
Pods with Prometheus annotations are auto-scraped:
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9090"
  prometheus.io/path: "/metrics"
```

### Check Pod Logs Directly
```bash
# Follow logs
kubectl logs -f -n heezy deployment/about-website

# Last 100 lines
kubectl logs --tail=100 -n heezy deployment/about-website

# All containers in pod
kubectl logs -n heezy <pod-name> --all-containers
```

## Secrets Management

### Add New Secret
```bash
# Store in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "production/heezy/my-app" \
  --secret-string '{"DB_PASSWORD":"xxx","API_KEY":"yyy"}' \
  --region us-east-2
```

### Create ExternalSecret
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

### Use in Deployment
```yaml
envFrom:
- secretRef:
    name: my-app-secrets
```

## Storage

### Request Storage
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
  namespace: heezy
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  # storageClassName: rook-ceph-block  # Optional (it's default)
```

### Use in Pod
```yaml
volumeMounts:
- name: data
  mountPath: /data
volumes:
- name: data
  persistentVolumeClaim:
    claimName: my-app-data
```

## Troubleshooting

### ExternalSecret not syncing
```bash
kubectl describe externalsecret <name> -n heezy
kubectl logs -n external-secrets deployment/external-secrets
```

### Image pull errors
```bash
# Verify ECR secret exists
kubectl get secret ecr-credentials -n heezy

# If missing, run ansible-heezy playbook to refresh
```

### Pod crashes
```bash
kubectl describe pod <pod-name> -n heezy
kubectl logs <pod-name> -n heezy --previous
```

### Cloudflare tunnel not routing
```bash
kubectl logs -n heezy -l app=cloudflared
kubectl describe configmap cloudflared-config -n heezy
```
