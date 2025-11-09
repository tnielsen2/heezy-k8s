# About Website

SWAG-based deployment for about.trentnielsen.me

## Architecture
- **Image**: LinuxServer SWAG (lscr.io/linuxserver/swag)
- **SSL**: Let's Encrypt via Cloudflare DNS
- **Files**: Copied from `src/` to persistent storage
- **Secrets**: AWS Secrets Manager (`production/heezy/about/swag`)

## Deployment
```bash
kubectl apply -k apps/about-website/
./apps/about-website/deploy-files.sh
```

## Required AWS Secret
Path: `production/heezy/about/swag`
```json
{
  "CF_ZONE_ID": "your_zone_id",
  "CF_ACCOUNT_ID": "your_account_id", 
  "CF_API_TOKEN": "your_api_token",
  "CF_TUNNEL_PASSWORD": "your_tunnel_password"
}
```