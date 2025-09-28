# Vibe Arcade Backend

A Go-based backend for a mobile gaming platform supporting turn-based board games (Dominoes and Chess).

## Features

- **Game Engines**: Pluggable game engine system supporting Dominoes and Chess
- **Real-time Communication**: WebSocket support for live gameplay
- **Matchmaking**: Intelligent matchmaking system with rating-based pairing
- **Authentication**: JWT-based authentication with refresh tokens
- **RESTful API**: Complete REST API for game management
- **Database**: PostgreSQL with Redis for caching and queues
- **Containerized**: Docker and Docker Compose support

## Architecture

### Game Engine System
- **Interface-based Design**: Common `GameEngine` interface for all games
- **Plugin Architecture**: Easy addition of new games
- **Move Validation**: Server-side move validation and game state management
- **Game State**: JSON-based game state storage

### Real-time Features
- **WebSocket Hub**: Central hub for managing WebSocket connections
- **Room Management**: Game rooms for players and spectators
- **Live Updates**: Real-time game updates and chat messages

### Matchmaking
- **Rating-based**: Matches players based on skill rating
- **Tolerance System**: Gradually increases rating tolerance for faster matching
- **Queue Management**: Redis-based queue system with automatic cleanup

## Quick Start

### Prerequisites
- Go 1.21+
- Docker and Docker Compose
- PostgreSQL 15+ (if running locally)
- Redis 7+ (if running locally)

### Development Setup

1. **Clone and setup**:
```bash
git clone <repository>
cd mobile-game/backend
cp .env.example .env
```

2. **Start with Docker**:
```bash
make dev-setup
```

3. **Run locally**:
```bash
make run
```

### Using Make Commands

```bash
# Development
make dev              # Start full development environment
make run              # Run application locally
make test             # Run tests
make test-coverage    # Run tests with coverage

# Docker
make docker-up        # Start all services
make docker-down      # Stop all services
make docker-logs      # View logs

# Code quality
make fmt              # Format code
make lint             # Lint code (requires golangci-lint)

# Build
make build            # Build for development
make prod-build       # Build for production
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login user
- `POST /api/v1/auth/refresh` - Refresh access token

### Games
- `GET /api/v1/games` - List games (with filters)
- `POST /api/v1/games` - Create new game
- `GET /api/v1/games/:id` - Get game details
- `POST /api/v1/games/:id/join` - Join game
- `POST /api/v1/games/:id/move` - Make a move

### User
- `GET /api/v1/user/profile` - Get user profile and stats

### WebSocket
- `GET /api/v1/ws` - WebSocket endpoint for real-time communication

## WebSocket Messages

### Client to Server
```json
{
  "type": "join_room",
  "room_id": "game-uuid",
  "player_id": "user-uuid",
  "data": {},
  "timestamp": "2023-01-01T00:00:00Z"
}
```

### Server to Client
```json
{
  "type": "game_update",
  "room_id": "game-uuid",
  "player_id": "user-uuid",
  "data": {"game_state": "..."},
  "timestamp": "2023-01-01T00:00:00Z"
}
```

## Game Implementation

### Adding a New Game

1. **Implement GameEngine interface**:
```go
type MyGameEngine struct{}

func (e *MyGameEngine) Initialize() (json.RawMessage, error) { /* ... */ }
func (e *MyGameEngine) ValidateMove(gameState, move json.RawMessage, playerID uuid.UUID) error { /* ... */ }
func (e *MyGameEngine) ApplyMove(gameState, move json.RawMessage, playerID uuid.UUID) (json.RawMessage, error) { /* ... */ }
func (e *MyGameEngine) GetGameStatus(gameState json.RawMessage) GameStatusInfo { /* ... */ }
func (e *MyGameEngine) GetPossibleMoves(gameState json.RawMessage, playerID uuid.UUID) ([]json.RawMessage, error) { /* ... */ }
func (e *MyGameEngine) GetGameType() models.GameType { return "my_game" }
```

2. **Register in main.go**:
```go
registry.Register("my_game", NewMyGameEngine())
```

3. **Update database enum**:
```sql
ALTER TYPE game_type_enum ADD VALUE 'my_game';
```

## Environment Variables

See `.env.example` for all available configuration options.

### Key Variables
- `JWT_SECRET`: Secret key for JWT signing (change in production!)
- `DB_*`: Database connection settings
- `REDIS_*`: Redis connection settings
- `SERVER_PORT`: Server port (default: 8181)

## Database Schema

### Tables
- `users`: User accounts and authentication
- `user_stats`: User game statistics and ratings
- `games`: Game instances and state
- `moves`: Move history for games

### Indexes
Optimized indexes for:
- User lookups (email, username)
- Game queries (status, type, players)
- Move history (game_id, player_id)

## Testing

```bash
# Run all tests
make test

# Run with coverage
make test-coverage

# Run specific package
go test ./internal/game/
```

## Production Deployment

1. **Build production image**:
```bash
make prod-build
docker build -t vibe-arcade-backend .
```

2. **Deploy with proper environment**:
- Set strong `JWT_SECRET`
- Configure production database
- Set up proper Redis instance
- Configure reverse proxy (nginx/traefik)

## Contributing

1. Follow Go conventions and fmt
2. Add tests for new features
3. Update documentation
4. Use conventional commit messages

## License

[Add your license here]