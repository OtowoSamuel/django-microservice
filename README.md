# Django Microservice API

A Django-based microservice with REST API endpoints for background task processing, deployed on AWS EKS with full CI/CD automation.

## Project Overview

This project implements a microservice that:
- Provides REST API endpoints using Django and Django REST Framework
- Processes background tasks using Celery and Redis
- Uses PostgreSQL for data persistence
- Integrates token-based authentication
- Includes comprehensive API documentation with Swagger/OpenAPI
- Is fully containerized with Docker
- Runs on Kubernetes (AWS EKS) with robust infrastructure as code

## Architecture

### Backend Components

- **Django + DRF**: Core web framework and REST API implementation
- **Celery**: Background task processing
- **Redis**: Message broker for Celery and result backend
- **PostgreSQL**: Database for persistent storage
- **Gunicorn**: WSGI HTTP server for production
- **Nginx**: (Optional) HTTP server and reverse proxy (when using local deployment)

### Infrastructure Components

- **AWS EKS**: Managed Kubernetes service
- **AWS ECR**: Container registry for Docker images
- **AWS EBS**: Persistent storage for PostgreSQL
- **AWS Load Balancer**: Traffic management and public access
- **Terraform**: Infrastructure as code

### CI/CD Pipeline

- **GitHub Actions**: Automated build and deployment
- **Docker**: Containerization
- **AWS ECR**: Container registry

## API Endpoints

### Authentication

All API endpoints require token authentication. Include the token in the request header:

```
Authorization: Token <your-token>
```

A default token is available for testing: `Token a2646fef3ce417ecba425253834db1313d2d463a`

### Task Processing

- **POST /api/process/**
  - Process a new task
  - Payload:
    ```json
    {
      "email": "user@example.com",
      "message": "Hello World"
    }
    ```
  - Response:
    ```json
    {
      "task_id": "uuid-task-id",
      "status": "PENDING"
    }
    ```

- **GET /api/status/<task_id>/**
  - Get status of a task
  - Response:
    ```json
    {
      "task_id": "uuid-task-id",
      "status": "SUCCESS",
      "result": "Task completed successfully"
    }
    ```

### Documentation

- **GET /swagger/** - Swagger UI for API documentation
- **GET /api/** - DRF browsable API
- **GET /admin/** - Django admin interface

## Local Development Setup

### Prerequisites

- Docker and Docker Compose
- Python 3.9+
- Git

### Installation

1. Clone the repository
   ```bash
   git clone <repository-url>
   cd django-microservice
   ```

2. Start the application using Docker Compose
   ```bash
   docker-compose up -d
   ```

3. Access the application at http://localhost:8000

### Manual Development Setup (without Docker)

1. Create a virtual environment
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies
   ```bash
   pip install -r requirements.txt
   ```

3. Set up environment variables
   ```bash
   export DJANGO_SETTINGS_MODULE=core.settings
   export DATABASE_URL=postgres://postgres:postgres@localhost:5432/django_microservice
   export CELERY_BROKER_URL=redis://localhost:6379/0
   export CELERY_RESULT_BACKEND=redis://localhost:6379/0
   export SECRET_KEY=your-secret-key-here
   ```

4. Start Redis and PostgreSQL (via Docker or locally)
   ```bash
   docker run -d -p 6379:6379 redis:6-alpine
   docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=django_microservice postgres:13-alpine
   ```

5. Run migrations
   ```bash
   python manage.py migrate
   ```

6. Create a superuser (for admin access)
   ```bash
   python manage.py createsuperuser
   ```

7. Start the development server
   ```bash
   python manage.py runserver
   ```

8. Start the Celery worker in a separate terminal
   ```bash
   celery -A core worker --loglevel=info
   ```

## AWS Deployment

### Prerequisites

- AWS CLI configured with appropriate credentials
- kubectl installed
- Terraform installed

### Deployment Options

#### 1. Automated Deployment with GitHub Actions (Recommended)

1. Push your code to GitHub

2. Configure GitHub Secrets in your repository:
   - `AWS_ACCESS_KEY_ID`: Your IAM user's access key
   - `AWS_SECRET_ACCESS_KEY`: Your IAM user's secret key

3. Push to the main/master branch to trigger the workflow

4. The GitHub Actions workflow will:
   - Build the Docker image
   - Push to ECR
   - Deploy to EKS
   - Restart the deployments

#### 2. Manual Deployment with Terraform and kubectl

1. Apply the Terraform configuration
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

2. Build and push the Docker image
   ```bash
   docker build -t django-microservice:latest .
   docker tag django-microservice:latest <your-aws-account-id>.dkr.ecr.<region>.amazonaws.com/django-microservice:latest
   aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <your-aws-account-id>.dkr.ecr.<region>.amazonaws.com
   docker push <your-aws-account-id>.dkr.ecr.<region>.amazonaws.com/django-microservice:latest
   ```

3. Deploy to Kubernetes
   ```bash
   export ECR_REPO_URL=<your-aws-account-id>.dkr.ecr.<region>.amazonaws.com/django-microservice
   cat microservices-k8.yml | sed "s|\${ECR_REPO_URL}|$ECR_REPO_URL|g" | kubectl apply -f -
   ```

#### 3. Quick Deployment with deploy.sh

For convenience, use the included deploy.sh script:
```bash
chmod +x deploy.sh
./deploy.sh
```

## Infrastructure as Code

All infrastructure is defined in Terraform:

- EKS cluster setup
- IAM roles and policies
- ECR repository
- Storage classes and persistent volumes
- Security groups and networking

The Terraform code is located in the `terraform/` directory.

## Monitoring and Logging

- AWS CloudWatch integration for logs and metrics
- Health endpoints for liveness and readiness probes

## Load Testing

For load testing, we recommend using Locust or Apache JMeter to simulate traffic to the API endpoints.

## Security Considerations

- Token-based authentication for API access
- ALLOWED_HOSTS configuration for Django
- Proper environment variable usage
- IAM roles with least privilege principle

## Future Enhancements

- Implement email notifications for task completion
- Add real-time status updates with WebSockets
- Implement more sophisticated authentication (OAuth2, JWT)
- Set up automated backups for PostgreSQL
- Add comprehensive test coverage
