#!/bin/bash

# Get the project name
if [ -z "$1" ]; then
   echo "Usage: $0 <project-name>"
  exit 1
fi

PROJECT_NAME=$1

# Create the directory structure
mkdir -p $PROJECT_NAME/cmd
mkdir -p $PROJECT_NAME/pkg/api/handlers
mkdir -p $PROJECT_NAME/pkg/api/middleware
mkdir -p $PROJECT_NAME/pkg/config
mkdir -p $PROJECT_NAME/pkg/db/migrations
mkdir -p $PROJECT_NAME/pkg/db/repository
mkdir -p $PROJECT_NAME/pkg/domain/models
mkdir -p $PROJECT_NAME/pkg/domain/services
mkdir -p $PROJECT_NAME/pkg/utils
mkdir -p $PROJECT_NAME/internal/app
mkdir -p $PROJECT_NAME/internal/auth
mkdir -p $PROJECT_NAME/internal/wire
mkdir -p $PROJECT_NAME/proto
mkdir -p $PROJECT_NAME/build
mkdir -p $PROJECT_NAME/k8s

# Create boilerplate files
echo "package main

func main() {
    println(\"Hello, World!\")
}" > $PROJECT_NAME/cmd/main.go

echo "package handlers

func HealthCheck() string {
    return \"OK\"
}" > $PROJECT_NAME/pkg/api/handlers/health.go

echo "package config

type Config struct {
    AppName string
}" > $PROJECT_NAME/pkg/config/config.go

echo "package app

import \"fmt\"

func Run() {
    fmt.Println(\"App started\")
}" > $PROJECT_NAME/internal/app/app.go

echo "package main

import (
    \"${PROJECT_NAME}/pkg/config\"
    \"${PROJECT_NAME}/pkg/db/repository\"
    \"${PROJECT_NAME}/pkg/domain/services\"

    \"github.com/google/wire\"
)

func InitializeApp() (*services.UserService, error) {
    wire.Build(
        config.NewConfig,
        repository.NewUserRepository,
        services.NewUserService,
    )
    return &services.UserService{}, nil
}" > $PROJECT_NAME/internal/wire/injector.go

echo "# Protocol Buffers Folder
# Place your .proto files here
syntax = \"proto3\";

package myproject;

message Example {
  string id = 1;
}" > $PROJECT_NAME/proto/example.proto

echo "# Dockerfile for Go service
FROM golang:1.20
WORKDIR /app
COPY . .
RUN go build -o main .
CMD [\"./main\"]" > $PROJECT_NAME/build/Dockerfile

echo "# Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${PROJECT_NAME}-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ${PROJECT_NAME}
  template:
    metadata:
      labels:
        app: ${PROJECT_NAME}
    spec:
      containers:
      - name: ${PROJECT_NAME}
        image: <image-placeholder>
        ports:
        - containerPort: 8080" > $PROJECT_NAME/k8s/deployment.yaml

echo "module $PROJECT_NAME

go 1.20" > $PROJECT_NAME/go.mod

# Add README.md
echo "# $PROJECT_NAME
This is a scaffolded Go project with support for:
- Protocol Buffers (.proto files)
- Dependency injection using Google Wire
- Kubernetes manifests
- Docker setup

## Getting Started
1. Place your .proto files in the \`proto/\` directory.
2. Use \`wire\` to generate the dependency injection code.
3. Build and deploy the service." > $PROJECT_NAME/README.md

echo "Project structure for $PROJECT_NAME created!"
