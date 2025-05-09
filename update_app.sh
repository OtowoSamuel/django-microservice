#!/bin/bash
# Script to update the Django application in Kubernetes

# Variables
ECR_REPO_URL="343218225856.dkr.ecr.us-east-1.amazonaws.com/django-microservice"
TAG="latest"

echo "Building new Docker image with health check endpoint..."
docker build -t $ECR_REPO_URL:$TAG .

echo "Authenticating with AWS ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO_URL

echo "Pushing new image to ECR..."
docker push $ECR_REPO_URL:$TAG

echo "Applying a rolling restart to the web pods..."
kubectl rollout restart deployment web

echo "Waiting for deployment to complete..."
kubectl rollout status deployment web

echo "Checking updated pod status..."
kubectl get pods -l component=web

echo "Done! Your application should now respond to health checks properly."