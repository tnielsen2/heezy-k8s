# kubectl Useful Commands

Quick reference for managing pods, deployments, and troubleshooting in the Nebula MicroK8s cluster.

## Pod Management

```bash
# List pods
kubectl get pods -n heezy
kubectl get pods -n heezy -o wide  # Show node placement & IPs

# Delete pod (will restart if managed by deployment)
kubectl delete pod <pod-name> -n heezy

# Force delete stuck pod
kubectl delete pod <pod-name> -n heezy --grace-period=0 --force
```

## Deployments

```bash
# Restart deployment (rolling restart)
kubectl rollout restart deployment/<app-name> -n heezy

# Scale deployment
kubectl scale deployment/<app-name> --replicas=0 -n heezy  # Stop
kubectl scale deployment/<app-name> --replicas=1 -n heezy  # Start

# Update image
kubectl set image deployment/<app-name> <container-name>=<new-image> -n heezy

# Rollback deployment
kubectl rollout undo deployment/<app-name> -n heezy

# Check rollout status
kubectl rollout status deployment/<app-name> -n heezy
```

## Troubleshooting

```bash
# Describe pod (events, status, errors)
kubectl describe pod <pod-name> -n heezy

# View logs
kubectl logs <pod-name> -n heezy
kubectl logs <pod-name> -n heezy --tail=50 -f  # Follow last 50 lines
kubectl logs <pod-name> -n heezy --previous     # Previous crashed container

# Execute commands in pod
kubectl exec -it <pod-name> -n heezy -- /bin/bash
kubectl exec <pod-name> -n heezy -- ls /config

# Port forward for local testing
kubectl port-forward <pod-name> 8080:80 -n heezy
```

## Resources

```bash
# Get all resources
kubectl get all -n heezy

# Check services & endpoints
kubectl get svc -n heezy
kubectl get endpoints -n heezy

# Check ingress
kubectl get ingress -n heezy

# Check PVCs
kubectl get pvc -n heezy
```

## Secrets

```bash
# List secrets
kubectl get secrets -n heezy

# Check ExternalSecret sync status
kubectl describe externalsecret <name> -n heezy

# View secret (base64 encoded)
kubectl get secret <name> -n heezy -o yaml
```

## Cleanup

```bash
# Delete deployment (removes pods)
kubectl delete deployment <app-name> -n heezy

# Delete all resources for an app
kubectl delete -k apps/<app-name>/

# Delete stuck namespace
kubectl delete namespace <name> --grace-period=0 --force
```

## Common Scenarios

### App not updating after push
```bash
kubectl rollout restart deployment/about-website -n heezy
```

### Pod stuck in CrashLoopBackOff
```bash
kubectl logs <pod-name> -n heezy --previous
kubectl describe pod <pod-name> -n heezy
```

### Clear everything and redeploy
```bash
kubectl delete -k apps/about-website/
kubectl apply -k apps/about-website/
```

### Check if secrets synced from AWS
```bash
kubectl get externalsecret -n heezy
kubectl describe externalsecret <name> -n heezy
```

### Why isn't my pod starting?
```bash
kubectl get pod <pod-name> -n heezy
kubectl describe pod <pod-name> -n heezy | grep -A 10 Events
kubectl logs <pod-name> -n heezy
```

### Why can't I reach my service?
```bash
kubectl get svc,endpoints,ingress -n heezy
kubectl logs -n heezy -l app=cloudflared --tail=20
```
