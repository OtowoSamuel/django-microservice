# Django Microservice with Celery and Redis

A Django-based microservice that provides a REST API for processing background tasks using Celery and Redis. This application is containerized with Docker and deployed on AWS using Terraform and Kubernetes.

## Architecture Overview

This project implements a microservice architecture with the following components:

- **Web Service**: Django + Django REST Framework
- **Background Task Processing**: Celery
- **Message Broker/Results Backend**: Redis
- **Database**: PostgreSQL
- **API Documentation**: Swagger/OpenAPI
- **Containerization**: Docker
- **Orchestration**: Kubernetes (EKS)
- **Infrastructure as Code**: Terraform

## Features

- REST API endpoints for processing tasks and checking their status
- Background task processing via Celery workers
- API documentation via Swagger UI
- Token-based authentication
- Containerized application for easy deployment
- Kubernetes deployment for scalability and reliability
- Terraform scripts for infrastructure provisioning

## API Endpoints

- `POST /api/process/`: Submit a task for background processing
  ```json
  {
    "email": "user@example.com",
    "message": "Hello World"
  }
  ```

- `GET /api/status/<task_id>/`: Check the status of a background task

- `/swagger/`: API documentation using Swagger UI

- `/admin/`: Django admin interface

## Local Development Setup

### Prerequisites

- Docker and Docker Compose
- Python 3.9+
- pip

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```
SECRET_KEY=your_secret_key
DB_NAME=django_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=db
DB_PORT=5432
POSTGRES_DB=django_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

### Running with Docker Compose

1. Build and start the containers:
   ```bash
   docker-compose up --build
   ```

2. Access the API at http://localhost:8000

3. Access the Swagger documentation at http://localhost:8000/swagger/

### Running without Docker

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Start Redis server (required for Celery)

3. Configure environment variables

4. Run migrations:
   ```bash
   python manage.py migrate
   ```

5. Start the Django development server:
   ```bash
   python manage.py runserver
   ```

6. Start Celery worker:
   ```bash
   celery -A core worker --loglevel=info
   ```

## Deployment

### AWS Deployment with Terraform and Kubernetes

This project is configured for deployment on AWS EKS (Elastic Kubernetes Service) using Terraform.

#### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed
- kubectl installed

#### Deployment Steps

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Apply Terraform configuration:
   ```bash
   terraform apply
   ```

4. Configure kubectl to connect to the EKS cluster:
   ```bash
   aws eks update-kubeconfig --name django-microservice-cluster
   ```

5. Deploy the application to Kubernetes:
   ```bash
   kubectl apply -f ../microservices-k8.yml
   ```

6. Verify deployment:
   ```bash
   kubectl get pods
   kubectl get svc
   ```

## Project Structure

- `core/`: Main Django project settings
- `tasks/`: Django app containing the API and task processing logic
- `terraform/`: Terraform scripts for AWS deployment
- `kubernetes/`: Kubernetes configuration files
- `Dockerfile`: Docker configuration
- `docker-compose.yml`: Docker Compose configuration for local development
- `requirements.txt`: Python dependencies
- `manage.py`: Django management script

## Technologies

- **Backend**: Django, Django REST Framework
- **Task Processing**: Celery
- **Database**: PostgreSQL
- **Cache/Message Broker**: Redis
- **Containerization**: Docker
- **Orchestration**: Kubernetes (EKS)
- **Infrastructure**: AWS (EC2, EKS, RDS, etc.)
- **IaC**: Terraform
- **Documentation**: Swagger/OpenAPI

## License

[MIT License](LICENSE)

## Author

SmallClosedWorld Developer
