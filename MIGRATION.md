# Service Migration Guide

## Architecture Decisions

### Cloudflare Tunnel
Centralized deployment (2 replicas) routes all services via internal cluster DNS. Add new services by updating ConfigMap.

### Storage
- **Config volumes:** `rook-ceph-block` (ReadWriteOnce) - fast block storage
- **Shared data:** `rook-cephfs` (ReadWriteMany) - shared filesystem for media

### Secrets
AWS Secrets Manager via External Secrets Operator (configured by ansible-heezy).

### CI/CD
GitHub Actions with self-hosted runner. ArgoCD optional for future GitOps.

## Migration Checklist

### Pre-Migration
- [ ] Backup Docker Compose volumes
- [ ] Document current environment variables
- [ ] Note any custom configurations
- [ ] Test Cloudflare Tunnel connectivity

### Per-Service Migration

#### 1. Sonarr
```bash
cp -r apps/_template apps/sonarr
cd apps/sonarr

# Edit deployment.yaml
sed -i '' 's/APP_NAME/sonarr/g' *.yaml
sed -i '' 's|IMAGE_NAME:TAG|linuxserver/sonarr:latest|g' deployment.yaml
sed -i '' 's/PORT/8989/g' *.yaml

# Adjust storage sizes if needed
# Deploy
kubectl apply -k .
```

#### 2. Radarr
```bash
cp -r apps/_template apps/radarr
cd apps/radarr
sed -i '' 's/APP_NAME/radarr/g' *.yaml
sed -i '' 's|IMAGE_NAME:TAG|linuxserver/radarr:latest|g' deployment.yaml
sed -i '' 's/PORT/7878/g' *.yaml
kubectl apply -k .
```

#### 3. SABnzbd
```bash
cp -r apps/_template apps/sabnzbd
cd apps/sabnzbd
sed -i '' 's/APP_NAME/sabnzbd/g' *.yaml
sed -i '' 's|IMAGE_NAME:TAG|linuxserver/sabnzbd:latest|g' deployment.yaml
sed -i '' 's/PORT/8080/g' *.yaml
kubectl apply -k .
```

#### 4. Overseerr
```bash
cp -r apps/_template apps/overseerr
cd apps/overseerr
sed -i '' 's/APP_NAME/overseerr/g' *.yaml
sed -i '' 's|IMAGE_NAME:TAG|linuxserver/overseerr:latest|g' deployment.yaml
sed -i '' 's/PORT/5055/g' *.yaml
kubectl apply -k .
```

#### 5. Tautulli
```bash
cp -r apps/_template apps/tautulli
cd apps/tautulli
sed -i '' 's/APP_NAME/tautulli/g' *.yaml
sed -i '' 's|IMAGE_NAME:TAG|linuxserver/tautulli:latest|g' deployment.yaml
sed -i '' 's/PORT/8181/g' *.yaml
kubectl apply -k .
```

#### 6. NZBHydra2
```bash
cp -r apps/_template apps/nzbhydra
cd apps/nzbhydra
sed -i '' 's/APP_NAME/nzbhydra/g' *.yaml
sed -i '' 's|IMAGE_NAME:TAG|linuxserver/nzbhydra2:latest|g' deployment.yaml
sed -i '' 's/PORT/5076/g' *.yaml
kubectl apply -k .
```

#### 7. Ombi
```bash
cp -r apps/_template apps/ombi
cd apps/ombi
sed -i '' 's/APP_NAME/ombi/g' *.yaml
sed -i '' 's|IMAGE_NAME:TAG|linuxserver/ombi:latest|g' deployment.yaml
sed -i '' 's/PORT/3579/g' *.yaml
kubectl apply -k .
```

#### 8. Pi-hole
```bash
cp -r apps/_template apps/pihole
cd apps/pihole
sed -i '' 's/APP_NAME/pihole/g' *.yaml
sed -i '' 's|IMAGE_NAME:TAG|pihole/pihole:latest|g' deployment.yaml
sed -i '' 's/PORT/80/g' *.yaml

# Add Pi-hole specific env vars to deployment.yaml
# - WEBPASSWORD
# - SERVERIP

kubectl apply -k .
```

#### 9. EmulatorJS
```bash
cp -r apps/_template apps/emulatorjs
cd apps/emulatorjs
sed -i '' 's/APP_NAME/emulatorjs/g' *.yaml
sed -i '' 's|IMAGE_NAME:TAG|linuxserver/emulatorjs:latest|g' deployment.yaml
sed -i '' 's/PORT/3000/g' *.yaml
kubectl apply -k .
```

### Post-Migration
- [ ] Update Cloudflare Tunnel config with all services
- [ ] Test each service endpoint
- [ ] Migrate data from Docker volumes to PVCs
- [ ] Update DNS records if needed
- [ ] Monitor resource usage
- [ ] Adjust resource limits based on actual usage

## Data Migration

### Copy data from Docker volumes to PVCs:
```bash
# Example for Sonarr
POD=$(kubectl get pod -n heezy -l app=sonarr -o jsonpath='{.items[0].metadata.name}')

# Copy config
kubectl cp /path/to/docker/sonarr/config $POD:/config -n heezy

# For shared media, mount CephFS and copy directly
```

## Cloudflare Tunnel Updates

After deploying each service, update `base/cloudflare-tunnel.yaml`:

```yaml
ingress:
  - hostname: about.trentnielsen.me
    service: http://about-website.heezy.svc.cluster.local:80
  - hostname: sonarr.trentnielsen.me
    service: http://sonarr.heezy.svc.cluster.local:8989
  - hostname: radarr.trentnielsen.me
    service: http://radarr.heezy.svc.cluster.local:7878
  - hostname: overseerr.trentnielsen.me
    service: http://overseerr.heezy.svc.cluster.local:5055
  - hostname: tautulli.trentnielsen.me
    service: http://tautulli.heezy.svc.cluster.local:8181
  - hostname: sabnzbd.trentnielsen.me
    service: http://sabnzbd.heezy.svc.cluster.local:8080
  - hostname: nzbhydra.trentnielsen.me
    service: http://nzbhydra.heezy.svc.cluster.local:5076
  - hostname: ombi.trentnielsen.me
    service: http://ombi.heezy.svc.cluster.local:3579
  - hostname: pihole.trentnielsen.me
    service: http://pihole.heezy.svc.cluster.local:80
  - hostname: emulatorjs.trentnielsen.me
    service: http://emulatorjs.heezy.svc.cluster.local:3000
  - service: http_status:404
```

Apply changes:
```bash
kubectl apply -f base/cloudflare-tunnel.yaml
kubectl rollout restart deployment/cloudflared -n heezy
```

## Troubleshooting

### Pod won't start
```bash
kubectl describe pod <pod-name> -n heezy
kubectl logs <pod-name> -n heezy
```

### PVC not binding
```bash
kubectl get pvc -n heezy
kubectl describe pvc <pvc-name> -n heezy
# Check Rook-Ceph status
kubectl get pods -n rook-ceph
```

### Service not accessible
```bash
kubectl get ingress -n heezy
kubectl get svc -n heezy
kubectl logs -n heezy -l app=cloudflared
```

### ECR pull fails
```bash
# Refresh ECR secret (expires after 12 hours)
./scripts/setup-ecr-secret.sh
kubectl rollout restart deployment/<app-name> -n heezy
```
