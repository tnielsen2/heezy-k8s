# Logging with Prometheus/LGTM Stack

## Overview
Your Prometheus/LGTM (Loki, Grafana, Tempo, Mimir) stack automatically collects logs from all pods. No sidecar needed - Promtail runs as DaemonSet on each node.

## How It Works

```
Pod stdout/stderr → Node logs → Promtail (DaemonSet) → Loki → Grafana
```

Promtail scrapes logs from `/var/log/pods/` on each node.

## Viewing Logs

### In Grafana
1. Navigate to Explore
2. Select Loki data source
3. Query examples:

```logql
# All logs from heezy namespace
{namespace="heezy"}

# Specific app
{namespace="heezy", app="about-website"}

# Specific pod
{namespace="heezy", pod="about-website-xxx"}

# Error logs only
{namespace="heezy"} |= "error"

# Exclude health checks
{namespace="heezy", app="about-website"} != "GET /health"

# Rate of errors
rate({namespace="heezy"} |= "error" [5m])
```

### Via kubectl
```bash
# Follow logs
kubectl logs -f -n heezy deployment/about-website

# Last 100 lines
kubectl logs --tail=100 -n heezy deployment/about-website

# All containers in pod
kubectl logs -n heezy <pod-name> --all-containers

# Previous container (after crash)
kubectl logs -n heezy <pod-name> --previous
```

## Best Practices

### 1. Use Structured Logging
Output JSON for better parsing:

```json
{"level":"info","msg":"Request processed","method":"GET","path":"/","status":200,"duration_ms":12}
```

Loki can parse JSON automatically:
```logql
{namespace="heezy"} | json | status >= 400
```

### 2. Add Meaningful Labels
Labels in your deployment help filter logs:

```yaml
metadata:
  labels:
    app: my-app
    component: backend
    version: v1.2.3
```

Query by label:
```logql
{namespace="heezy", component="backend"}
```

### 3. Log Levels
Use standard levels: DEBUG, INFO, WARN, ERROR, FATAL

Filter in Grafana:
```logql
{namespace="heezy"} |= "level=error"
```

### 4. Avoid Excessive Logging
- Don't log every request (use sampling)
- Exclude health check endpoints
- Use appropriate log levels

## Common Queries

### Application Errors
```logql
{namespace="heezy", app="about-website"} |= "error" or "ERROR" or "exception"
```

### HTTP 5xx Errors
```logql
{namespace="heezy"} | json | status >= 500
```

### Slow Requests
```logql
{namespace="heezy"} | json | duration_ms > 1000
```

### Pod Restarts
```logql
{namespace="heezy"} |= "Liveness probe failed" or "Readiness probe failed"
```

### Cloudflare Tunnel Issues
```logql
{namespace="heezy", app="cloudflared"}
```

## Alerting

Create alerts in Grafana for:
- High error rate
- Pod crashes
- Slow response times

Example alert rule:
```yaml
- alert: HighErrorRate
  expr: |
    rate({namespace="heezy"} |= "error" [5m]) > 0.1
  for: 5m
  annotations:
    summary: High error rate in heezy namespace
```

## Log Retention

Loki retention configured in your LGTM stack (typically 30-90 days).

## Troubleshooting

### Logs not appearing in Grafana
```bash
# Check Promtail is running
kubectl get pods -n monitoring -l app=promtail

# Check Promtail logs
kubectl logs -n monitoring -l app=promtail

# Verify Loki is receiving logs
kubectl logs -n monitoring -l app=loki
```

### Missing logs for specific pod
```bash
# Verify pod is outputting to stdout/stderr
kubectl logs -n heezy <pod-name>

# Check pod labels
kubectl get pod -n heezy <pod-name> --show-labels
```

## No Sidecar Needed

Unlike some logging solutions (Fluentd, Filebeat), Promtail runs as a DaemonSet on nodes, not as sidecars. Your application pods don't need any logging configuration - just write to stdout/stderr.

## Performance Impact

Minimal - Promtail uses ~50MB RAM per node and scrapes logs efficiently. No impact on application pods.
