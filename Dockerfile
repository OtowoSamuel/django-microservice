# Base stage for common dependencies
FROM python:3.13-slim-bookworm as base

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt 

# Test stage
FROM base as test
COPY . .
# Run tests during build
RUN python manage.py test

# Production stage
FROM base as production
COPY . .
EXPOSE 8000

CMD ["bash", "-c", "python manage.py migrate && python manage.py collectstatic --noinput && gunicorn --bind 0.0.0.0:8000 core.wsgi:application"]
