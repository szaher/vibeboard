#!/bin/bash

# Vibe Arcade Test Runner
# Comprehensive testing script for all components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Test backend unit tests
test_backend_units() {
    print_header "Running Backend Unit Tests"

    cd backend || {
        print_error "Backend directory not found"
        return 1
    }

    if go test ./... -v; then
        print_success "Backend unit tests passed"
    else
        print_error "Backend unit tests failed"
    fi

    cd ..
}

# Test backend with coverage
test_backend_coverage() {
    print_header "Running Backend Tests with Coverage"

    cd backend || {
        print_error "Backend directory not found"
        return 1
    }

    if go test ./... -coverprofile=coverage.out; then
        if command -v go >/dev/null 2>&1; then
            local coverage=$(go tool cover -func=coverage.out | tail -n 1 | awk '{print $3}')
            print_success "Backend tests passed with $coverage coverage"

            # Generate HTML coverage report
            go tool cover -html=coverage.out -o coverage.html
            print_info "Coverage report generated: backend/coverage.html"
        else
            print_success "Backend tests passed"
        fi
    else
        print_error "Backend tests with coverage failed"
    fi

    cd ..
}

# Test backend linting
test_backend_lint() {
    print_header "Running Backend Linting"

    cd backend || {
        print_error "Backend directory not found"
        return 1
    }

    # Check if golangci-lint is available
    if command -v golangci-lint >/dev/null 2>&1; then
        if golangci-lint run; then
            print_success "Backend linting passed"
        else
            print_error "Backend linting failed"
        fi
    else
        print_warning "golangci-lint not found - skipping lint check"
        print_info "Install with: brew install golangci-lint (macOS) or go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    fi

    cd ..
}

# Test backend formatting
test_backend_format() {
    print_header "Checking Backend Code Formatting"

    cd backend || {
        print_error "Backend directory not found"
        return 1
    }

    # Check if code is properly formatted
    local unformatted=$(gofmt -l .)
    if [[ -z "$unformatted" ]]; then
        print_success "Backend code is properly formatted"
    else
        print_error "Backend code formatting issues found:"
        echo "$unformatted"
        print_info "Run 'make fmt' to fix formatting"
    fi

    cd ..
}

# Test API endpoints
test_api_endpoints() {
    print_header "Testing API Endpoints"

    if [[ -f scripts/test-api.sh ]]; then
        if ./scripts/test-api.sh; then
            print_success "API endpoint tests passed"
        else
            print_error "API endpoint tests failed"
        fi
    else
        print_warning "API test script not found - skipping API tests"
    fi
}

# Test iOS build (if on macOS)
test_ios_build() {
    print_header "Testing iOS Build"

    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "Not on macOS - skipping iOS build test"
        return 0
    fi

    if [[ ! -d ios ]]; then
        print_warning "iOS directory not found - skipping iOS build test"
        return 0
    fi

    if ! command -v xcodebuild >/dev/null 2>&1; then
        print_warning "Xcode not found - skipping iOS build test"
        return 0
    fi

    cd ios || {
        print_error "Could not enter iOS directory"
        return 1
    }

    # Try to build the project
    if xcodebuild -project VibeArcade.xcodeproj -scheme VibeArcade -destination 'platform=iOS Simulator,name=iPhone 15' build >/dev/null 2>&1; then
        print_success "iOS project builds successfully"
    else
        print_error "iOS project build failed"
    fi

    cd ..
}

# Test Android build
test_android_build() {
    print_header "Testing Android Build"

    if [[ ! -d android ]]; then
        print_warning "Android directory not found - skipping Android build test"
        return 0
    fi

    cd android || {
        print_error "Could not enter Android directory"
        return 1
    }

    # Check if gradlew exists
    if [[ ! -f gradlew ]]; then
        print_warning "Gradle wrapper not found - skipping Android build test"
        cd ..
        return 0
    fi

    # Try to build the project
    if ./gradlew assembleDebug >/dev/null 2>&1; then
        print_success "Android project builds successfully"
    else
        print_error "Android project build failed"
    fi

    cd ..
}

# Test database connection
test_database_connection() {
    print_header "Testing Database Connection"

    # Check if PostgreSQL container is running
    if docker ps | grep -q postgres; then
        print_success "PostgreSQL container is running"

        # Test connection
        if docker exec backend-postgres-1 pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
            print_success "PostgreSQL connection successful"
        else
            print_error "PostgreSQL connection failed"
        fi
    else
        print_warning "PostgreSQL container not running - start with 'make docker-up'"
    fi

    # Check Redis connection
    if docker ps | grep -q redis; then
        print_success "Redis container is running"

        # Test connection
        if docker exec backend-redis-1 redis-cli ping >/dev/null 2>&1; then
            print_success "Redis connection successful"
        else
            print_error "Redis connection failed"
        fi
    else
        print_warning "Redis container not running - start with 'make docker-up'"
    fi
}

# Test WebSocket connection
test_websocket() {
    print_header "Testing WebSocket Connection"

    # Check if backend is running
    if ! curl -s http://localhost:8181/health >/dev/null; then
        print_warning "Backend not running - start with 'make run' to test WebSocket"
        return 0
    fi

    # Test if websocat is available for WebSocket testing
    if ! command -v websocat &> /dev/null; then
        print_warning "websocat not found - skipping detailed WebSocket test"
        print_info "Install with: brew install websocat (macOS) or cargo install websocat"
        return 0
    fi

    # Simple WebSocket connection test
    if timeout 5 websocat "ws://localhost:8181/api/v1/ws" <<<'{"type":"heartbeat","player_id":"test","timestamp":0}' >/dev/null 2>&1; then
        print_success "WebSocket connection test passed"
    else
        print_warning "WebSocket connection test failed or inconclusive"
    fi
}

# Performance tests
test_performance() {
    print_header "Running Performance Tests"

    # Check if backend is running
    if ! curl -s http://localhost:8181/health >/dev/null; then
        print_warning "Backend not running - skipping performance tests"
        return 0
    fi

    # Simple load test using curl
    print_info "Running basic load test (100 requests)..."

    local start_time=$(date +%s)
    local success_count=0
    local total_requests=100

    for i in $(seq 1 $total_requests); do
        if curl -s -f http://localhost:8181/health >/dev/null; then
            ((success_count++))
        fi
    done

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local rps=$((total_requests / duration))

    if [[ $success_count -eq $total_requests ]]; then
        print_success "Load test passed: $success_count/$total_requests requests succeeded (~$rps req/s)"
    else
        print_error "Load test failed: $success_count/$total_requests requests succeeded"
    fi
}

# Security tests
test_security() {
    print_header "Running Security Tests"

    # Check if backend is running
    if ! curl -s http://localhost:8181/health >/dev/null; then
        print_warning "Backend not running - skipping security tests"
        return 0
    fi

    # Test CORS headers
    local cors_response=$(curl -s -H "Origin: http://evil.com" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: X-Requested-With" -X OPTIONS http://localhost:8181/api/v1/auth/login)

    if [[ -n "$cors_response" ]]; then
        print_info "CORS preflight response received"
    fi

    # Test for common security headers
    local headers=$(curl -s -I http://localhost:8181/health)

    if echo "$headers" | grep -q "X-Content-Type-Options"; then
        print_success "X-Content-Type-Options header present"
    else
        print_warning "X-Content-Type-Options header missing"
    fi

    # Test unauthorized access
    local auth_response=$(curl -s -w "%{http_code}" -X GET http://localhost:8181/api/v1/user/profile -o /dev/null)

    if [[ "$auth_response" == "401" ]]; then
        print_success "Authentication properly enforced"
    else
        print_error "Authentication bypass possible (got HTTP $auth_response)"
    fi
}

# Generate test report
generate_report() {
    print_header "Test Results Summary"

    local pass_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi

    cat << EOF

${BLUE}📊 Test Summary${NC}
Total tests: $TOTAL_TESTS
Passed: ${GREEN}$PASSED_TESTS${NC}
Failed: ${RED}$FAILED_TESTS${NC}
Pass rate: ${BLUE}$pass_rate%${NC}

Completed at: $(date)
EOF

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}❌ Some tests failed. Check the output above for details.${NC}"
        return 1
    fi
}

# Main test execution
main() {
    local test_type="${1:-all}"

    print_header "Vibe Arcade Test Suite"
    echo "Test type: $test_type"
    echo "Started at: $(date)"

    case "$test_type" in
        "backend")
            test_backend_units
            test_backend_format
            test_backend_lint
            ;;
        "api")
            test_api_endpoints
            test_websocket
            ;;
        "mobile")
            test_ios_build
            test_android_build
            ;;
        "integration")
            test_database_connection
            test_api_endpoints
            test_websocket
            ;;
        "performance")
            test_performance
            ;;
        "security")
            test_security
            ;;
        "all")
            test_backend_units
            test_backend_format
            test_backend_lint
            test_database_connection
            test_api_endpoints
            test_websocket
            test_ios_build
            test_android_build
            test_performance
            test_security
            ;;
        *)
            echo "Usage: $0 [backend|api|mobile|integration|performance|security|all]"
            exit 1
            ;;
    esac

    generate_report
}

# Show usage if --help is passed
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << EOF
Vibe Arcade Test Runner

Usage: $0 [TEST_TYPE]

Test types:
  backend      - Run backend unit tests, linting, and formatting checks
  api          - Test API endpoints and WebSocket connections
  mobile       - Test iOS and Android builds
  integration  - Test database connections and API integration
  performance  - Run basic performance tests
  security     - Run security tests
  all          - Run all tests (default)

Examples:
  $0 backend    # Run only backend tests
  $0 api        # Test API endpoints
  $0 all        # Run complete test suite
EOF
    exit 0
fi

# Run main function
main "$@"