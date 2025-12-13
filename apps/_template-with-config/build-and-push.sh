#!/bin/bash
set -e

ECR_REGISTRY="025066240222.dkr.ecr.us-east-2.amazonaws.com"
IMAGE_NAME="APP_NAME"
TAG="${1:-latest}"

docker build -t ${IMAGE_NAME}:${TAG} .
docker tag ${IMAGE_NAME}:${TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${ECR_REGISTRY}
aws ecr describe-repositories --repository-names ${IMAGE_NAME} --region us-east-2 || \
  aws ecr create-repository --repository-name ${IMAGE_NAME} --region us-east-2
docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}
echo "Done! Image: ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}"
