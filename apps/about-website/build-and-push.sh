#!/bin/bash
set -e

ECR_REGISTRY="025066240222.dkr.ecr.us-east-2.amazonaws.com"
IMAGE_NAME="swag-about"
TAG="${1:-latest}"

echo "Building image..."
docker build -t ${IMAGE_NAME}:${TAG} .

echo "Tagging for ECR..."
docker tag ${IMAGE_NAME}:${TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}

echo "Logging into ECR..."
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${ECR_REGISTRY}

echo "Creating ECR repository if it doesn't exist..."
aws ecr describe-repositories --repository-names ${IMAGE_NAME} --region us-east-2 || \
  aws ecr create-repository --repository-name ${IMAGE_NAME} --region us-east-2

echo "Pushing to ECR..."
docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}

echo "Done! Image: ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}"
