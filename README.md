# Django Microservice API

A Django-based microservice that provides a REST API for background task processing, deployed on AWS using EKS, Docker, and CI/CD principles.

## Live Deployment

The application is currently deployed on AWS EKS at:
- API: http://a1fb5209bdd12496e9c8e7aa92864dec-662626986.us-east-1.elb.amazonaws.com/api/
- API Documentation: http://a1fb5209bdd12496e9c8e7aa92864dec-662626986.us-east-1.elb.amazonaws.com/swagger/

**Important**: The API requires token authentication. To access the API, use the following authentication token:

```
Token a2646fef3ce417ecba425253834db1313d2d463a
```

### Testing the API with Authentication

You can test the API using curl with the authentication token:

```bash
# Create a new task
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Token a2646fef3ce417ecba425253834db1313d2d463a" \
  -d '{"email": "test@example.com", "message": "Hello from the API!"}' \
  http://a1fb5209bdd12496e9c8e7aa92864dec-662626986.us-east-1.elb.amazonaws.com/api/process/

# Check task status (replace TASK_ID with the ID received from the previous call)
curl -H "Authorization: Token a2646fef3ce417ecba425253834db1313d2d463a" \
  http://a1fb5209bdd12496e9c8e7aa92864dec-662626986.us-east-1.elb.amazonaws.com/api/status/TASK_ID/
```

### Swagger UI Authentication

To use the Swagger UI documentation:
1. Open http://a1fb5209bdd12496e9c8e7aa92864dec-662626986.us-east-1.elb.amazonaws.com/swagger/
2. Click the "Authorize" button
3. Enter the token: `Token a2646fef3ce417ecba425253834db1313d2d463a`
4. Click "Authorize" and close the dialog
5. Now you can test the API endpoints directly from the Swagger UI

## Architecture Overview

This application is built as a microservice architecture with the following components:

1. **Web API Layer**: Django + Django REST Framework
   - Handles API requests and responses
   - Validates input data
   - Queues background tasks

2. **Background Processing**: Celery + Redis
   - Celery workers process tasks asynchronously
   - Redis serves as message broker and result backend
   - Simulates time-consuming operations

3. **Database Layer**: PostgreSQL
   - Stores task data, status, and results
   - Persists application state

4. **Container Orchestration**: Kubernetes (AWS EKS)
   - Manages application containers
   - Provides scaling and resilience
   - Handles service discovery

5. **CI/CD Pipeline**: GitHub Actions
   - Automated testing
   - Containerization
   - Deployment to EKS

## API Documentation

The API is documented using Swagger/OpenAPI and can be accessed at `/swagger/` when the application is running.

### Endpoints

1. **Process Task**
   - URL: `/api/process/`
   - Method: `POST`
   - Request Body:
     ```json
     {
       "email": "user@example.com",
       "message": "Hello World"
     }
     ```
   - Response: 
     ```json
     {
       "task_id": "12345-67890-abcdef",
       "status": "pending"
     }
     ```

2. **Get Task Status**
   - URL: `/api/status/<task_id>/`
   - Method: `GET`
   - Response:
     ```json
     {
       "task_id": "12345-67890-abcdef",
       "status": "completed", // or "pending", "failed"
       "result": "Task processed successfully"
     }
     ```

### Authentication

The API uses token-based authentication:

1. **Obtain Auth Token**
   - URL: `/api-token-auth/`
   - Method: `POST`
   - Request Body:
     ```json
     {
       "username": "your_username",
       "password": "your_password"
     }
     ```
   - Response:
     ```json
     {
       "token": "your_auth_token"
     }
     ```

2. **Using the token**
   - Include the token in the Authorization header for protected endpoints:
     ```
     Authorization: Token your_auth_token
     ```
   - This can be tested in Swagger UI by clicking the "Authorize" button and entering the token

3. **User Management**
   - Standard Django authentication URLs are available at `/accounts/`
   - Admin interface is available at `/admin/` for user management

## Local Development Setup

### Prerequisites

- Docker and Docker Compose
- Python 3.10+
- AWS CLI (for deployment)
- Terraform (for infrastructure provisioning)

### Running Locally with Docker Compose

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/django-microservice.git
   cd django-microservice
   ```

2. Start the services:
   ```bash
   docker-compose up -d
   ```

3. Access the API at `http://localhost:8000/api/`
   - Swagger UI: `http://localhost:8000/swagger/`

4. To stop the services:
   ```bash
   docker-compose down
   ```

## Deployment to AWS

### Infrastructure Setup with Terraform

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Plan the infrastructure:
   ```bash
   terraform plan -var="region=us-east-1"
   ```

4. Apply the configuration:
   ```bash
   terraform apply -var="region=us-east-1"
   ```

This will create:
- EKS cluster
- ECR repository
- Required IAM roles and policies
- Network resources
- PostgreSQL and Redis services in Kubernetes

### CI/CD Pipeline

The application uses GitHub Actions for CI/CD. The workflow is defined in `.github/workflows/deploy-to-eks.yml` and performs the following steps:

1. Builds the Docker image
2. Pushes the image to AWS ECR
3. Deploys to EKS cluster
4. Runs database migrations
5. Updates environment variables

To use this pipeline, you'll need to set up the following GitHub secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `SECRET_KEY`

## Kubernetes Resources

The application is deployed to Kubernetes using the `microservices-k8.yml` manifest, which includes:

- Web API Deployment and Service
- Celery Worker Deployment
- PostgreSQL Deployment and Service
- Redis Deployment and Service
- Persistent Volume Claims for data persistence

## Environment Variables

The application uses the following environment variables:

- `DB_NAME`: PostgreSQL database name
- `DB_USER`: PostgreSQL username
- `DB_PASSWORD`: PostgreSQL password
- `DB_HOST`: PostgreSQL host
- `DB_PORT`: PostgreSQL port (default: 5432)
- `SECRET_KEY`: Django secret key
- `DEBUG`: Enable debug mode (true/false)
- `CELERY_BROKER_URL`: Redis URL for Celery broker
- `CELERY_RESULT_BACKEND`: Redis URL for Celery results

## Cloud Architecture Details

The application is deployed on AWS with the following components:

1. **Amazon EKS (Elastic Kubernetes Service)**
   - Manages the Kubernetes cluster
   - Runs application containers

2. **Amazon ECR (Elastic Container Registry)**
   - Stores Docker images
   - Integrates with CI/CD pipeline

3. **AWS IAM**
   - Manages access and permissions
   - Integrates with Kubernetes RBAC

4. **AWS Load Balancer**
   - Provides public access to the API
   - Handles SSL termination

## Monitoring and Logging

The application integrates with:
- AWS CloudWatch for logs and metrics
- Kubernetes Dashboard for cluster monitoring
- ELK stack for centralized logging (optional setup)

## Security Considerations

- Environment variables for sensitive information
- IAM roles for service accounts
- Network policies in Kubernetes
- API rate limiting
- Secure database connections

## License

This project is licensed under the MIT License - see the LICENSE file for details.
