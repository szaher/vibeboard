#!/bin/bash

# Vibe Arcade Development Environment Setup Script
# This script automates the setup of the local development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    local missing_deps=()

    # Check Go
    if command_exists go; then
        local go_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
        if [[ $(echo "$go_version >= 1.21" | bc -l) -eq 1 ]]; then
            print_success "Go $go_version is installed"
        else
            print_error "Go version $go_version is too old (requires 1.21+)"
            missing_deps+=("go")
        fi
    else
        print_error "Go is not installed"
        missing_deps+=("go")
    fi

    # Check Docker
    if command_exists docker; then
        print_success "Docker is installed"
    else
        print_error "Docker is not installed"
        missing_deps+=("docker")
    fi

    # Check Docker Compose
    if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
        print_success "Docker Compose is available"
    else
        print_error "Docker Compose is not available"
        missing_deps+=("docker-compose")
    fi

    # Check make
    if command_exists make; then
        print_success "Make is installed"
    else
        print_error "Make is not installed"
        missing_deps+=("make")
    fi

    # Check git
    if command_exists git; then
        print_success "Git is installed"
    else
        print_error "Git is not installed"
        missing_deps+=("git")
    fi

    # Optional tools
    if command_exists curl; then
        print_success "curl is installed"
    else
        print_warning "curl is not installed (recommended for API testing)"
    fi

    if command_exists jq; then
        print_success "jq is installed"
    else
        print_warning "jq is not installed (helpful for JSON parsing)"
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo -e "\nPlease install the missing dependencies and run this script again."
        echo "Installation guides:"
        echo "  Go: https://golang.org/doc/install"
        echo "  Docker: https://docs.docker.com/get-docker/"
        echo "  Make: Usually pre-installed on macOS/Linux"
        exit 1
    fi
}

# Setup backend environment
setup_backend() {
    print_header "Setting Up Backend Environment"

    cd backend || {
        print_error "Backend directory not found"
        exit 1
    }

    # Download Go dependencies
    print_info "Downloading Go dependencies..."
    if go mod download; then
        print_success "Go dependencies downloaded"
    else
        print_error "Failed to download Go dependencies"
        exit 1
    fi

    # Create .env file if it doesn't exist
    if [[ ! -f .env ]]; then
        if [[ -f .env.example ]]; then
            cp .env.example .env
            print_success "Created .env file from .env.example"
        else
            print_warning ".env.example not found, creating basic .env file"
            cat > .env << EOF
# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=vibe_arcade
DB_PASSWORD=vibe_arcade_password
DB_NAME=vibe_arcade

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-super-secure-jwt-secret-change-in-production

# Server
SERVER_HOST=localhost
SERVER_PORT=8181

# Environment
ENV=development

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8181
EOF
            print_success "Created basic .env file"
        fi
    else
        print_success ".env file already exists"
    fi

    cd ..
}

# Start database services
start_services() {
    print_header "Starting Database Services"

    cd backend || exit 1

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi

    print_info "Starting PostgreSQL and Redis..."
    if make docker-up; then
        print_success "Database services started"
    else
        print_error "Failed to start database services"
        exit 1
    fi

    print_info "Waiting for services to be ready..."
    sleep 10

    # Check if PostgreSQL is ready
    for i in {1..30}; do
        if docker exec backend-postgres-1 pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
            print_success "PostgreSQL is ready"
            break
        fi
        if [[ $i -eq 30 ]]; then
            print_error "PostgreSQL failed to start after 30 seconds"
            exit 1
        fi
        sleep 1
    done

    cd ..
}

# Run database migrations
run_migrations() {
    print_header "Running Database Migrations"

    cd backend || exit 1

    print_info "Running database migrations..."
    if make migrate-up; then
        print_success "Database migrations completed"
    else
        print_error "Database migrations failed"
        exit 1
    fi

    cd ..
}

# Build and test backend
test_backend() {
    print_header "Building and Testing Backend"

    cd backend || exit 1

    print_info "Building backend..."
    if go build -o bin/server cmd/server/main.go; then
        print_success "Backend built successfully"
    else
        print_error "Backend build failed"
        exit 1
    fi

    print_info "Running backend tests..."
    if go test ./...; then
        print_success "All backend tests passed"
    else
        print_warning "Some backend tests failed"
    fi

    cd ..
}

# Check mobile development setup
check_mobile_setup() {
    print_header "Checking Mobile Development Setup"

    # Check iOS development
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists xcodebuild; then
            local xcode_version=$(xcodebuild -version | head -n1 | grep -oE '[0-9]+\.[0-9]+')
            print_success "Xcode $xcode_version is installed"
        else
            print_warning "Xcode is not installed (required for iOS development)"
        fi
    else
        print_info "Not on macOS - iOS development not available"
    fi

    # Check Android development
    if [[ -n "$ANDROID_HOME" ]]; then
        print_success "Android SDK is configured"
    else
        print_warning "ANDROID_HOME is not set (required for Android development)"
    fi

    if command_exists adb; then
        print_success "Android Debug Bridge (adb) is available"
    else
        print_warning "adb is not available (install Android SDK)"
    fi
}

# Display next steps
show_next_steps() {
    print_header "Setup Complete! Next Steps"

    cat << EOF

${GREEN}✓ Development environment is ready!${NC}

To start developing:

${BLUE}1. Start the backend server:${NC}
   cd backend && make run

${BLUE}2. Test the API:${NC}
   ./scripts/test-api.sh

${BLUE}3. For iOS development:${NC}
   cd ios && open VibeArcade.xcodeproj

${BLUE}4. For Android development:${NC}
   cd android
   # Open in Android Studio

${BLUE}5. Monitor services:${NC}
   cd backend && make docker-logs

${BLUE}6. Stop services when done:${NC}
   cd backend && make docker-down

${YELLOW}Useful URLs:${NC}
  - Backend API: http://localhost:8181/api/v1
  - Health check: http://localhost:8181/health
  - WebSocket: ws://localhost:8181/api/v1/ws

${YELLOW}Useful commands:${NC}
  - Backend tests: cd backend && go test ./...
  - Format code: cd backend && make fmt
  - View logs: cd backend && make docker-logs
  - API testing: ./scripts/test-api.sh

For detailed documentation, see DEVELOPMENT.md

Happy coding! 🎮
EOF
}

# Main setup function
main() {
    print_header "Vibe Arcade Development Environment Setup"
    echo "This script will set up your local development environment."
    echo "Started at: $(date)"

    check_prerequisites
    setup_backend
    start_services
    run_migrations
    test_backend
    check_mobile_setup
    show_next_steps

    print_success "Setup completed successfully!"
}

# Run main function
main "$@"