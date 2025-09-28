#!/bin/bash

# Vibe Arcade Docker Utilities
# Helper scripts for managing Docker containers and services

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

# Show container status
show_status() {
    print_header "Container Status"

    local containers=$(docker ps -a --filter name=backend --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

    if [[ -n "$containers" ]]; then
        echo "$containers"
    else
        print_info "No Vibe Arcade containers found"
    fi
}

# Show detailed container information
show_details() {
    print_header "Detailed Container Information"

    local postgres_container=$(docker ps -q --filter name=backend-postgres)
    local redis_container=$(docker ps -q --filter name=backend-redis)

    if [[ -n "$postgres_container" ]]; then
        print_info "PostgreSQL Container Details:"
        docker inspect $postgres_container --format='
  Image: {{.Config.Image}}
  Status: {{.State.Status}}
  Started: {{.State.StartedAt}}
  Ports: {{range $p, $conf := .NetworkSettings.Ports}}{{$p}} -> {{(index $conf 0).HostPort}} {{end}}
  Environment: {{range .Config.Env}}{{if contains . "POSTGRES"}}{{.}} {{end}}{{end}}'
        echo
    fi

    if [[ -n "$redis_container" ]]; then
        print_info "Redis Container Details:"
        docker inspect $redis_container --format='
  Image: {{.Config.Image}}
  Status: {{.State.Status}}
  Started: {{.State.StartedAt}}
  Ports: {{range $p, $conf := .NetworkSettings.Ports}}{{$p}} -> {{(index $conf 0).HostPort}} {{end}}'
        echo
    fi
}

# Show logs for specific service
show_logs() {
    local service="$1"
    local lines="${2:-50}"

    if [[ -z "$service" ]]; then
        print_error "Service name required. Available: postgres, redis, all"
        return 1
    fi

    case "$service" in
        "postgres")
            print_header "PostgreSQL Logs (last $lines lines)"
            docker logs --tail=$lines backend-postgres-1 2>/dev/null || docker logs --tail=$lines $(docker ps -q --filter name=backend-postgres)
            ;;
        "redis")
            print_header "Redis Logs (last $lines lines)"
            docker logs --tail=$lines backend-redis-1 2>/dev/null || docker logs --tail=$lines $(docker ps -q --filter name=backend-redis)
            ;;
        "all")
            show_logs postgres $lines
            show_logs redis $lines
            ;;
        *)
            print_error "Unknown service: $service. Available: postgres, redis, all"
            return 1
            ;;
    esac
}

# Follow logs for specific service
follow_logs() {
    local service="$1"

    if [[ -z "$service" ]]; then
        print_error "Service name required. Available: postgres, redis"
        return 1
    fi

    case "$service" in
        "postgres")
            print_info "Following PostgreSQL logs (Ctrl+C to stop)..."
            docker logs -f backend-postgres-1 2>/dev/null || docker logs -f $(docker ps -q --filter name=backend-postgres)
            ;;
        "redis")
            print_info "Following Redis logs (Ctrl+C to stop)..."
            docker logs -f backend-redis-1 2>/dev/null || docker logs -f $(docker ps -q --filter name=backend-redis)
            ;;
        *)
            print_error "Unknown service: $service. Available: postgres, redis"
            return 1
            ;;
    esac
}

# Connect to database
connect_db() {
    local postgres_container=$(docker ps -q --filter name=backend-postgres)

    if [[ -z "$postgres_container" ]]; then
        print_error "PostgreSQL container not running"
        print_info "Start with: cd backend && make docker-up"
        return 1
    fi

    print_info "Connecting to PostgreSQL database..."
    print_info "(Use \\q to quit)"
    docker exec -it $postgres_container psql -U vibe_arcade -d vibe_arcade
}

# Connect to Redis
connect_redis() {
    local redis_container=$(docker ps -q --filter name=backend-redis)

    if [[ -z "$redis_container" ]]; then
        print_error "Redis container not running"
        print_info "Start with: cd backend && make docker-up"
        return 1
    fi

    print_info "Connecting to Redis CLI..."
    print_info "(Use 'exit' to quit)"
    docker exec -it $redis_container redis-cli
}

# Clean up containers and volumes
cleanup() {
    local force="$1"

    print_header "Cleaning Up Docker Resources"

    if [[ "$force" != "--force" ]]; then
        print_warning "This will stop and remove all Vibe Arcade containers and volumes."
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cleanup cancelled"
            return 0
        fi
    fi

    # Stop containers
    print_info "Stopping containers..."
    docker ps -q --filter name=backend | xargs -r docker stop

    # Remove containers
    print_info "Removing containers..."
    docker ps -aq --filter name=backend | xargs -r docker rm

    # Remove volumes
    print_info "Removing volumes..."
    docker volume ls -q --filter name=backend | xargs -r docker volume rm

    print_success "Cleanup completed"
}

# Reset development environment
reset_dev() {
    print_header "Resetting Development Environment"

    print_warning "This will:"
    echo "  - Stop all containers"
    echo "  - Remove containers and volumes"
    echo "  - Restart services"
    echo "  - Run migrations"

    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Reset cancelled"
        return 0
    fi

    cd backend || {
        print_error "Backend directory not found"
        return 1
    }

    # Stop and clean up
    make docker-down 2>/dev/null || true
    cleanup --force

    # Start fresh
    print_info "Starting fresh environment..."
    make docker-up

    print_info "Waiting for services..."
    sleep 10

    # Run migrations
    print_info "Running migrations..."
    make migrate-up

    print_success "Development environment reset completed"
    cd ..
}

# Show resource usage
show_resources() {
    print_header "Docker Resource Usage"

    # Show container resource usage
    print_info "Container Resource Usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" $(docker ps -q --filter name=backend) 2>/dev/null || echo "No containers running"

    echo

    # Show disk usage
    print_info "Docker Disk Usage:"
    docker system df

    echo

    # Show volumes
    print_info "Volumes:"
    docker volume ls --filter name=backend
}

# Backup database
backup_db() {
    local backup_file="backup_$(date +%Y%m%d_%H%M%S).sql"

    print_header "Creating Database Backup"

    local postgres_container=$(docker ps -q --filter name=backend-postgres)

    if [[ -z "$postgres_container" ]]; then
        print_error "PostgreSQL container not running"
        return 1
    fi

    print_info "Creating backup: $backup_file"

    if docker exec $postgres_container pg_dump -U vibe_arcade vibe_arcade > "$backup_file"; then
        print_success "Backup created: $backup_file"
    else
        print_error "Backup failed"
        rm -f "$backup_file"
        return 1
    fi
}

# Restore database
restore_db() {
    local backup_file="$1"

    if [[ -z "$backup_file" ]]; then
        print_error "Backup file required"
        print_info "Usage: $0 restore-db <backup_file.sql>"
        return 1
    fi

    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi

    print_header "Restoring Database"

    local postgres_container=$(docker ps -q --filter name=backend-postgres)

    if [[ -z "$postgres_container" ]]; then
        print_error "PostgreSQL container not running"
        return 1
    fi

    print_warning "This will replace the current database content"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Restore cancelled"
        return 0
    fi

    print_info "Restoring from: $backup_file"

    if docker exec -i $postgres_container psql -U vibe_arcade vibe_arcade < "$backup_file"; then
        print_success "Database restored successfully"
    else
        print_error "Restore failed"
        return 1
    fi
}

# Show help
show_help() {
    cat << EOF
Vibe Arcade Docker Utilities

Usage: $0 <command> [arguments]

Commands:
  status           Show container status
  details          Show detailed container information
  logs <service>   Show logs for service (postgres, redis, all)
  follow <service> Follow logs for service (postgres, redis)
  connect-db       Connect to PostgreSQL database
  connect-redis    Connect to Redis CLI
  cleanup          Clean up containers and volumes
  reset            Reset entire development environment
  resources        Show Docker resource usage
  backup-db        Create database backup
  restore-db <file> Restore database from backup
  help             Show this help message

Examples:
  $0 status                    # Show container status
  $0 logs postgres 100        # Show last 100 lines of PostgreSQL logs
  $0 follow redis             # Follow Redis logs
  $0 connect-db               # Connect to database
  $0 cleanup                  # Clean up Docker resources
  $0 backup-db                # Create database backup
  $0 restore-db backup.sql    # Restore from backup

Note: Run from project root directory
EOF
}

# Main function
main() {
    local command="$1"
    shift || true

    case "$command" in
        "status")
            show_status
            ;;
        "details")
            show_details
            ;;
        "logs")
            show_logs "$@"
            ;;
        "follow")
            follow_logs "$@"
            ;;
        "connect-db")
            connect_db
            ;;
        "connect-redis")
            connect_redis
            ;;
        "cleanup")
            cleanup "$@"
            ;;
        "reset")
            reset_dev
            ;;
        "resources")
            show_resources
            ;;
        "backup-db")
            backup_db
            ;;
        "restore-db")
            restore_db "$@"
            ;;
        "help"|"")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"