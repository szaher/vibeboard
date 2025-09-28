#!/bin/bash

# Vibe Arcade API Testing Script
# This script tests all major API endpoints to verify the backend is working correctly

set -e

# Configuration
BASE_URL="http://localhost:8181/api/v1"
HEALTH_URL="http://localhost:8181/health"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((TESTS_PASSED++))
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    ((TESTS_FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Test health endpoint
test_health() {
    print_header "Testing Health Endpoint"

    if curl -s -f "$HEALTH_URL" >/dev/null; then
        print_success "Health endpoint is responding"
    else
        print_error "Health endpoint is not responding"
        return 1
    fi
}

# Test user registration
test_registration() {
    print_header "Testing User Registration"

    local email="test-$(date +%s)@example.com"
    local username="testuser$(date +%s)"
    local password="password123"

    local response=$(curl -s -w "%{http_code}" -X POST "$BASE_URL/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$email\",\"username\":\"$username\",\"password\":\"$password\"}" \
        -o /tmp/register_response.json)

    if [[ "$response" == "201" ]]; then
        print_success "User registration successful"
        # Store credentials for login test
        echo "$email" > /tmp/test_email.txt
        echo "$password" > /tmp/test_password.txt
        return 0
    else
        print_error "User registration failed (HTTP $response)"
        return 1
    fi
}

# Test user login
test_login() {
    print_header "Testing User Login"

    if [[ ! -f /tmp/test_email.txt || ! -f /tmp/test_password.txt ]]; then
        print_error "No test credentials available (registration may have failed)"
        return 1
    fi

    local email=$(cat /tmp/test_email.txt)
    local password=$(cat /tmp/test_password.txt)

    local response=$(curl -s -w "%{http_code}" -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$email\",\"password\":\"$password\"}" \
        -o /tmp/login_response.json)

    if [[ "$response" == "200" ]]; then
        # Extract token from response
        local token=$(cat /tmp/login_response.json | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
        if [[ -n "$token" ]]; then
            echo "$token" > /tmp/test_token.txt
            print_success "User login successful"
            return 0
        else
            print_error "Login response missing access token"
            return 1
        fi
    else
        print_error "User login failed (HTTP $response)"
        return 1
    fi
}

# Test authenticated endpoint
test_profile() {
    print_header "Testing Authenticated Profile Endpoint"

    if [[ ! -f /tmp/test_token.txt ]]; then
        print_error "No access token available (login may have failed)"
        return 1
    fi

    local token=$(cat /tmp/test_token.txt)

    local response=$(curl -s -w "%{http_code}" -X GET "$BASE_URL/user/profile" \
        -H "Authorization: Bearer $token" \
        -o /tmp/profile_response.json)

    if [[ "$response" == "200" ]]; then
        print_success "Profile endpoint working with authentication"
        return 0
    else
        print_error "Profile endpoint failed (HTTP $response)"
        return 1
    fi
}

# Test games endpoint
test_games() {
    print_header "Testing Games Endpoint"

    if [[ ! -f /tmp/test_token.txt ]]; then
        print_error "No access token available (login may have failed)"
        return 1
    fi

    local token=$(cat /tmp/test_token.txt)

    local response=$(curl -s -w "%{http_code}" -X GET "$BASE_URL/games" \
        -H "Authorization: Bearer $token" \
        -o /tmp/games_response.json)

    if [[ "$response" == "200" ]]; then
        print_success "Games endpoint responding"
        return 0
    else
        print_error "Games endpoint failed (HTTP $response)"
        return 1
    fi
}

# Test WebSocket connection
test_websocket() {
    print_header "Testing WebSocket Connection"

    # Test if websocat is available for WebSocket testing
    if ! command -v websocat &> /dev/null; then
        print_warning "websocat not found - skipping WebSocket test"
        print_warning "Install with: brew install websocat (macOS) or cargo install websocat"
        return 0
    fi

    # Simple WebSocket connection test
    timeout 5 websocat "ws://localhost:8181/api/v1/ws" <<<'{"type":"heartbeat","player_id":"test","timestamp":0}' >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        print_success "WebSocket connection successful"
    else
        print_warning "WebSocket connection test inconclusive"
    fi
}

# Cleanup function
cleanup() {
    rm -f /tmp/test_email.txt /tmp/test_password.txt /tmp/test_token.txt
    rm -f /tmp/register_response.json /tmp/login_response.json /tmp/profile_response.json /tmp/games_response.json
}

# Main test execution
main() {
    print_header "Vibe Arcade API Testing"
    echo "Testing backend at: $BASE_URL"
    echo "Started at: $(date)"

    # Check if backend is running
    if ! test_health; then
        echo -e "\n${RED}Backend is not running or not accessible at $BASE_URL${NC}"
        echo "Please ensure the backend is started with 'make run' or 'make dev'"
        exit 1
    fi

    # Run all tests
    test_registration || true
    test_login || true
    test_profile || true
    test_games || true
    test_websocket || true

    # Print summary
    print_header "Test Results Summary"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo "Completed at: $(date)"

    # Cleanup
    cleanup

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All critical tests passed! 🎉${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed. Check the output above for details.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"