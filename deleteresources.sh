#!/bin/bash

AWS_REGION="us-east-1"
CLUSTER_NAME="django-microservice-cluster"
SERVICE_NAME="django-microservice"
REPO_NAME="django-microservice"
DB_INSTANCE_ID="django-microservice-db"
REDIS_CLUSTER_ID="django-microservice-redis"
LOG_GROUP="/ecs/django-microservice"
ROLE_NAME="ecs_task_execution_role"
SUBNET_GROUP_NAME="redis-subnet-group"
SECURITY_GROUP_NAME="eks-nodes-sg"
VPC_ID="vpc-03ef804adafe75364"  # Add your VPC ID here

echo "Deleting ECS service..."
SERVICE_ARN=$(aws ecs list-services --cluster "$CLUSTER_NAME" --region $AWS_REGION --query "serviceArns[?contains(@, '$SERVICE_NAME')]" --output text)
if [ -n "$SERVICE_ARN" ]; then
  aws ecs update-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --desired-count 0 --region $AWS_REGION
  aws ecs delete-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --force --region $AWS_REGION
else
  echo "ECS service not found. Skipping."
fi

echo "Deregistering ECS task definitions..."
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix "$SERVICE_NAME" --region $AWS_REGION --query "taskDefinitionArns[]" --output text)
for td in $TASK_DEFS; do
  aws ecs deregister-task-definition --task-definition "$td" --region $AWS_REGION
done

echo "Deleting ECS cluster..."
aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region $AWS_REGION | grep "$CLUSTER_NAME" &>/dev/null
if [ $? -eq 0 ]; then
  aws ecs delete-cluster --cluster "$CLUSTER_NAME" --region $AWS_REGION
else
  echo "ECS cluster not found. Skipping."
fi

echo "Deleting CloudWatch log group..."
aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region $AWS_REGION | grep "$LOG_GROUP" &>/dev/null
if [ $? -eq 0 ]; then
  aws logs delete-log-group --log-group-name "$LOG_GROUP" --region $AWS_REGION
else
  echo "Log group not found. Skipping."
fi

echo "Deleting RDS DB instance..."
aws rds describe-db-instances --region $AWS_REGION --query "DBInstances[?DBInstanceIdentifier=='$DB_INSTANCE_ID']" | grep "$DB_INSTANCE_ID" &>/dev/null
if [ $? -eq 0 ]; then
  aws rds delete-db-instance --db-instance-identifier "$DB_INSTANCE_ID" --skip-final-snapshot --region $AWS_REGION
else
  echo "RDS DB instance not found. Skipping."
fi

echo "Deleting Elasticache Redis cluster..."
aws elasticache describe-cache-clusters --region $AWS_REGION --query "CacheClusters[?CacheClusterId=='$REDIS_CLUSTER_ID']" | grep "$REDIS_CLUSTER_ID" &>/dev/null
if [ $? -eq 0 ]; then
  aws elasticache delete-cache-cluster --cache-cluster-id "$REDIS_CLUSTER_ID" --region $AWS_REGION
  echo "Waiting for Redis cluster to be deleted..."
  aws elasticache wait cache-cluster-deleted --cache-cluster-id "$REDIS_CLUSTER_ID" --region $AWS_REGION
else
  echo "Redis cluster not found. Skipping."
fi

echo "Deleting Elasticache subnet group..."
aws elasticache describe-cache-subnet-groups --region $AWS_REGION --query "CacheSubnetGroups[?CacheSubnetGroupName=='$SUBNET_GROUP_NAME']" | grep "$SUBNET_GROUP_NAME" &>/dev/null
if [ $? -eq 0 ]; then
  aws elasticache delete-cache-subnet-group --cache-subnet-group-name "$SUBNET_GROUP_NAME" --region $AWS_REGION
else
  echo "Subnet group not found. Skipping."
fi

echo "Deleting ECR repository..."
aws ecr describe-repositories --region $AWS_REGION --query "repositories[?repositoryName=='$REPO_NAME']" | grep "$REPO_NAME" &>/dev/null
if [ $? -eq 0 ]; then
  aws ecr delete-repository --repository-name "$REPO_NAME" --force --region $AWS_REGION
else
  echo "ECR repository not found. Skipping."
fi

echo "Detaching and deleting IAM role..."
ROLE_EXISTS=$(aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null)
if [ $? -eq 0 ]; then
  aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
  aws iam delete-role --role-name "$ROLE_NAME"
else
  echo "IAM role not found. Skipping."
fi

echo "Deleting VPC..."
VPC_EXISTS=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region $AWS_REGION --query "Vpcs[0].VpcId" --output text)
if [ "$VPC_EXISTS" != "None" ]; then
  echo "VPC found. Deleting..."
  aws ec2 delete-vpc --vpc-id "$VPC_ID" --region $AWS_REGION
else
  echo "VPC not found. Skipping."
fi

echo "Deleting Security Group..."
SG_EXISTS=$(aws ec2 describe-security-groups --filters Name=group-name,Values="$SECURITY_GROUP_NAME" --region $AWS_REGION --query "SecurityGroups[0].GroupId" --output text)
if [ "$SG_EXISTS" != "None" ]; then
  aws ec2 delete-security-group --group-id "$SG_EXISTS" --region $AWS_REGION
else
  echo "Security group $SECURITY_GROUP_NAME not found. Skipping."
fi

echo "✅ Cleanup complete."
