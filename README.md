# My Go Service

This repository contains a scaffolded Go project with the following features:

- **Clean Architecture**: Clear separation of concerns between API, domain, and infrastructure layers.
- **Dependency Injection**: Configured using [Google Wire](https://github.com/google/wire).
- **Protocol Buffers**: Support for `.proto` files for gRPC and serialization.
- **Containerization**: Docker setup for building and deploying the application.
- **Kubernetes Deployment**: Includes manifest files for deploying the application to a Kubernetes cluster.

---

## **Directory Breakdown**

### **1. `cmd/`**
The entry point of the application. This directory contains the `main.go` file, which initializes and starts the service.

### **2. `pkg/`**
This directory contains reusable packages and business logic.

- **`pkg/api/handlers/`**: Contains HTTP handlers (e.g., `health.go` for health check endpoints).
- **`pkg/api/middleware/`**: Contains middleware functions for authentication, logging, etc.
- **`pkg/config/`**: Handles configuration management (e.g., `config.go` for loading app settings).
- **`pkg/db/`**:
  - **`migrations/`**: Database migration files.
  - **`repository/`**: Implements data persistence logic (e.g., repositories for database access).
- **`pkg/domain/`**:
  - **`models/`**: Defines core business entities (e.g., `user.go`).
  - **`services/`**: Implements domain logic (e.g., `user_service.go`).
- **`pkg/utils/`**: Utility functions (e.g., logging, response formatting).

### **3. `internal/`**
Contains application-specific code that shouldn’t be reused in other projects.

- **`internal/app/`**: Application initialization logic (e.g., `app.go` for starting the server).
- **`internal/auth/`**: Handles authentication (e.g., JWT logic).
- **`internal/wire/`**: Contains the Wire injector configuration (`injector.go`).

### **4. `proto/`**
Holds `.proto` files for defining Protocol Buffers messages and gRPC services.  
Example: `example.proto` defines a simple gRPC message.

### **5. `build/`**
Contains build-related files such as the `Dockerfile`.

### **6. `k8s/`**
Contains Kubernetes manifest files for deploying the application to a cluster.

- **`deployment.yaml`**: Kubernetes Deployment configuration for the service.

### **7. `go.mod`**
The Go module file, which declares the dependencies of the project.

### **8. `README.md`**
This documentation file.

---

## **Setup Instructions**

### **1. Prerequisites**
- Go 1.20 or later
- Docker
- Kubernetes (kubectl)
- Protocol Buffers Compiler (`protoc`)
- Wire CLI:
  ```bash
  go install github.com/google/wire/cmd/wire@latest
