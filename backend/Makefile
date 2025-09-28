# Vibe Arcade Backend Makefile

.PHONY: build run test clean docker-build docker-up docker-down migrate-up migrate-down

# Variables
APP_NAME=vibe-arcade-backend
DOCKER_COMPOSE=docker-compose
GO=go

# Build the application
build:
	$(GO) build -o bin/$(APP_NAME) ./cmd/server

# Run the application locally
run:
	$(GO) run ./cmd/server

# Run tests
test:
	$(GO) test -v ./...

# Run tests with coverage
test-coverage:
	$(GO) test -v -coverprofile=coverage.out ./...
	$(GO) tool cover -html=coverage.out -o coverage.html

# Clean build artifacts
clean:
	rm -rf bin/
	rm -f coverage.out coverage.html

# Download dependencies
deps:
	$(GO) mod download
	$(GO) mod tidy

# Format code
fmt:
	$(GO) fmt ./...

# Lint code (requires golangci-lint)
lint:
	golangci-lint run

# Build Docker image
docker-build:
	docker build -t $(APP_NAME) .

# Start all services with Docker Compose
docker-up:
	$(DOCKER_COMPOSE) up -d

# Stop all services
docker-down:
	$(DOCKER_COMPOSE) down

# View logs
docker-logs:
	$(DOCKER_COMPOSE) logs -f

# Restart services
docker-restart:
	$(DOCKER_COMPOSE) restart

# Run database migrations
migrate-up:
	docker exec vibe-arcade-postgres psql -U vibe_arcade -d vibe_arcade -f /docker-entrypoint-initdb.d/migrations.sql

# Generate new migration (requires migrate tool)
migrate-create:
	migrate create -ext sql -dir scripts/migrations $(name)

# Setup development environment
dev-setup: deps docker-up
	@echo "Waiting for database to be ready..."
	@sleep 10
	@echo "Development environment is ready!"

# Full local development start
dev: docker-up run

# Production build
prod-build:
	CGO_ENABLED=0 GOOS=linux $(GO) build -a -installsuffix cgo -ldflags '-w -s' -o bin/$(APP_NAME) ./cmd/server

# Help
help:
	@echo "Available commands:"
	@echo "  build         - Build the application"
	@echo "  run           - Run the application locally"
	@echo "  test          - Run tests"
	@echo "  test-coverage - Run tests with coverage report"
	@echo "  clean         - Clean build artifacts"
	@echo "  deps          - Download and tidy dependencies"
	@echo "  fmt           - Format code"
	@echo "  lint          - Lint code"
	@echo "  docker-build  - Build Docker image"
	@echo "  docker-up     - Start services with Docker Compose"
	@echo "  docker-down   - Stop services"
	@echo "  docker-logs   - View service logs"
	@echo "  docker-restart- Restart services"
	@echo "  migrate-up    - Run database migrations"
	@echo "  dev-setup     - Setup development environment"
	@echo "  dev           - Start full development environment"
	@echo "  prod-build    - Build for production"