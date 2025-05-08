#!/bin/bash
# Automated deployment script for django-microservice

# Configuration
AWS_ACCOUNT_ID="343218225856"
AWS_REGION="us-east-1"
ECR_REPO_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/django-microservice"

# Color codes for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment process...${NC}"

# Step 1: Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t django-microservice:latest . || { echo -e "${RED}Docker build failed!${NC}"; exit 1; }
echo -e "${GREEN}Docker image built successfully!${NC}"

# Step 2: Tag and push to ECR
echo -e "${YELLOW}Logging in to ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL || { echo -e "${RED}ECR login failed!${NC}"; exit 1; }

echo -e "${YELLOW}Tagging Docker image...${NC}"
docker tag django-microservice:latest $ECR_REPO_URL:latest || { echo -e "${RED}Docker tag failed!${NC}"; exit 1; }

echo -e "${YELLOW}Pushing to ECR...${NC}"
docker push $ECR_REPO_URL:latest || { echo -e "${RED}Docker push failed!${NC}"; exit 1; }
echo -e "${GREEN}Image pushed to ECR successfully!${NC}"

# Step 3: Process Kubernetes YAML to replace variables
echo -e "${YELLOW}Processing Kubernetes manifests...${NC}"
cp microservices-k8.yml microservices-k8-processed.yml
sed -i "s|\${ECR_REPO_URL}|$ECR_REPO_URL|g" microservices-k8-processed.yml || { echo -e "${RED}Failed to process YAML!${NC}"; exit 1; }
echo -e "${GREEN}Kubernetes manifests processed!${NC}"

# Step 4: Apply to Kubernetes
echo -e "${YELLOW}Applying Kubernetes manifests...${NC}"
kubectl apply -f microservices-k8-processed.yml || { echo -e "${RED}Kubernetes apply failed!${NC}"; exit 1; }
echo -e "${GREEN}Kubernetes manifests applied!${NC}"

# Step 5: Restart deployments to pick up new image (since we're using :latest tag)
echo -e "${YELLOW}Restarting deployments...${NC}"
kubectl rollout restart deployment web || { echo -e "${RED}Failed to restart web deployment!${NC}"; exit 1; }
kubectl rollout restart deployment worker || { echo -e "${RED}Failed to restart worker deployment!${NC}"; exit 1; }
echo -e "${GREEN}Deployments restarted!${NC}"

# Step 6: Wait for deployments to be ready
echo -e "${YELLOW}Waiting for deployments to be ready...${NC}"
kubectl rollout status deployment web || { echo -e "${RED}Web deployment not ready!${NC}"; exit 1; }
kubectl rollout status deployment worker || { echo -e "${RED}Worker deployment not ready!${NC}"; exit 1; }

# Step 7: Clean up
rm microservices-k8-processed.yml

echo -e "${GREEN}Deployment completed successfully!${NC}"

# Print pod status
echo -e "${YELLOW}Current pod status:${NC}"
kubectl get pods -l app=django-app

echo -e "${YELLOW}To check the logs:${NC}"
echo "kubectl logs -l app=django-app,component=web --tail=100"

echo -e "${YELLOW}To access the application:${NC}"
LOAD_BALANCER=$(kubectl get svc -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].hostname}')
if [ -n "$LOAD_BALANCER" ]; then
  echo "http://$LOAD_BALANCER/"
else
  echo "No LoadBalancer found. Use port-forwarding to access the service locally:"
  echo "kubectl port-forward svc/web 8000:8000"
  echo "Then access: http://localhost:8000/"
fi