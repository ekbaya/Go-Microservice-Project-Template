#!/bin/bash
# Get the project name
if [ -z "$1" ]; then
   echo "Usage: $0 <SERVICE_NAME>"
   exit 1
fi
SERVICE_NAME=$1

# Create the directory structure
mkdir -p $SERVICE_NAME/cmd
mkdir -p $SERVICE_NAME/pkg/api/handlers
mkdir -p $SERVICE_NAME/pkg/api/middleware
mkdir -p $SERVICE_NAME/pkg/config
mkdir -p $SERVICE_NAME/pkg/db/migrations
mkdir -p $SERVICE_NAME/pkg/db/repository
mkdir -p $SERVICE_NAME/pkg/domain/models
mkdir -p $SERVICE_NAME/pkg/domain/services
mkdir -p $SERVICE_NAME/pkg/utils
mkdir -p $SERVICE_NAME/internal/app
mkdir -p $SERVICE_NAME/internal/"$SERVICE_NAME"
mkdir -p $SERVICE_NAME/internal/wire
mkdir -p $SERVICE_NAME/proto
mkdir -p $SERVICE_NAME/build
mkdir -p $SERVICE_NAME/k8s

# Create boilerplate files
echo "package main
func main() {
    println(\"Hello, World!\")
}" > $SERVICE_NAME/cmd/main.go
echo "package handlers
func HealthCheck() string {
    return \"OK\"
}" > $SERVICE_NAME/pkg/api/handlers/health.go
echo "package config
type Config struct {
    AppName string
}" > $SERVICE_NAME/pkg/config/config.go
echo "package app
import \"fmt\"
func Run() {
    fmt.Println(\"App started\")
}" > $SERVICE_NAME/internal/app/app.go
echo "package main
import (
    \"${SERVICE_NAME}/pkg/config\"
    \"${SERVICE_NAME}/pkg/db/repository\"
    \"${SERVICE_NAME}/pkg/domain/services\"
    \"github.com/google/wire\"
)
func InitializeApp() (*services.UserService, error) {
    wire.Build(
        config.NewConfig,
        repository.NewUserRepository,
        services.NewUserService,
    )
    return &services.UserService{}, nil
}" > $SERVICE_NAME/internal/wire/injector.go

echo "# Protocol Buffers Folder
# Place your .proto files here
syntax = \"proto3\";
package $SERVICE_NAME;

option go_package = "$SERVICE_NAME/proto";

service ExampleService {
    
}" > $SERVICE_NAME/proto/$SERVICE_NAME.proto


echo "# Dockerfile for Go service
# Build stage
FROM golang:1.22-alpine AS builder

# Add necessary build tools
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Copy the entire parent directory (including go.mod, go.sum, and other service directories)
COPY . .

# Download dependencies
RUN go mod download

# Build the specific service ("$SERVICE_NAME" in this case)
RUN CGO_ENABLED=0 GOOS=linux go build -o "$SERVICE_NAME"_service ./"$SERVICE_NAME"/cmd/main.go

# Final stage
FROM alpine:latest

# Install CA certificates
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Create config directory in the service path
RUN mkdir -p /app/"$SERVICE_NAME"/pkg/config

# Copy the binary from the builder stage
COPY --from=builder /app/"$SERVICE_NAME"_service .

# Copy the specific config file for "$SERVICE_NAME" service
COPY --from=builder /app/"$SERVICE_NAME"/pkg/config/config.yaml /app/"$SERVICE_NAME"/pkg/config/

# Copy the .env file from the build context (parent directory)
COPY .env /app/.env

# Set the environment variable to the config path
ENV SERVICE_CONFIG_PATH=/app/"$SERVICE_NAME"/pkg/config

# Expose HTTP and gRPC ports
EXPOSE 9001
EXPOSE 50050

# Run the service
CMD [\"./"$SERVICE_NAME"_service\"]" > $SERVICE_NAME/build/Dockerfile


echo "# Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "$SERVICE_NAME"-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: "$SERVICE_NAME"
  template:
    metadata:
      labels:
        app: "$SERVICE_NAME"
    spec:
      containers:
        - name: "$SERVICE_NAME"
          image: <account_id>.dkr.ecr.<region>.amazonaws.com/"$SERVICE_NAME":<image_tag>
          ports:
            - containerPort: 9001
            - containerPort: 50051
          env:
            - name: DB_HOST
              value: postgres-service
            - name: DB_PORT
              value: "5432"
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
            - name: DB_NAME
              value: "$SERVICE_NAME"
            - name: DB_SSL_MODE
              value: disable
            - name: RABBITMQ_URL
              value: "amqp://guest:guest@rabbitmq-service.default.svc.cluster.local:5672/"
          volumeMounts:
            - name: config-volume
              mountPath: /app/"$SERVICE_NAME"/pkg/config
      volumes:
        - name: config-volume
          configMap:
            name: "$SERVICE_NAME"-config" > $SERVICE_NAME/k8s/deployment.yaml

echo "# Kubernetes Service
apiVersion: v1
kind: Service
metadata:
  name: "$SERVICE_NAME"-service
spec:
  selector:
    app: "$SERVICE_NAME"
  ports:
    - name: http
      port: 9001
      targetPort: 9001
    - name: grpc
      port: 50051
      targetPort: 50051" > $SERVICE_NAME/k8s/service.yaml

echo "module $SERVICE_NAME
go 1.20" > $SERVICE_NAME/go.mod

# Add README.md
echo "# $SERVICE_NAME
This is a scaffolded Go project with support for:
- Protocol Buffers (.proto files)
- Dependency injection using Google Wire
- Kubernetes manifests
- Docker setup
## Getting Started
1. Place your .proto files in the \`proto/\` directory.
2. Use \`wire\` to generate the dependency injection code.
3. Build and deploy the service." > $SERVICE_NAME/README.md

# Generate the Jenkinsfile in the parent directory
cat <<EOF > $SERVICE_NAME/Jenkinsfile
pipeline {
    agent any

    stages {
        stage('Build & Tag Docker Image') {
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                        // AWS ECR login using the credentials and region provided in withAWS
                        sh "aws ecr get-login-password | docker login --username AWS --password-stdin \${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"

                        // Build the Docker image
                        sh "docker build -f $SERVICE_NAME/build/Dockerfile -t $SERVICE_NAME:latest ."
                        
                        // Tag the Docker image for ECR
                        sh "docker tag $SERVICE_NAME:latest \${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/$SERVICE_NAME:latest"
                    }
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                        // Push the Docker image to ECR
                        sh "docker push \${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/$SERVICE_NAME:latest"
                    }
                }
            }
        }
    }
}
EOF

echo "Project structure for $SERVICE_NAME created!"
