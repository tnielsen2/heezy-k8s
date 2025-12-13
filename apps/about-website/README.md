# About Website (SWAG)

## Setup

1. Copy SWAG config files from docker-compose setup:
```bash
cp -r /path/to/docker-compose-usenet/media-services/swag ./swag-config
```

2. Build and push image:
```bash
chmod +x build-and-push.sh
./build-and-push.sh
```

3. Update deployment.yaml image to: `025066240222.dkr.ecr.us-east-2.amazonaws.com/swag-about:latest`

4. Deploy:
```bash
kubectl apply -k .
```

## Config Files Structure
```
swag-config/
├── dns-conf/
│   └── cloudflare.ini
├── nginx/
│   ├── proxy-confs/
│   └── site-confs/
├── www/
└── tunnelconfig.yml
```
