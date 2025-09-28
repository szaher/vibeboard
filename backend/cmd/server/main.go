package main

import (
	"log"

	"github.com/joho/godotenv"
	"github.com/redis/go-redis/v9"

	"github.com/szaher/vibeboard/backend/api"
	"github.com/szaher/vibeboard/backend/internal/auth"
	"github.com/szaher/vibeboard/backend/internal/database"
	"github.com/szaher/vibeboard/backend/internal/game"
	"github.com/szaher/vibeboard/backend/internal/lobby"
	"github.com/szaher/vibeboard/backend/internal/models"
	"github.com/szaher/vibeboard/backend/internal/websocket"
	"github.com/szaher/vibeboard/backend/pkg/config"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Load configuration
	cfg := config.Load()

	// Initialize database
	db, err := database.NewDB(&cfg.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer func() {
		if err := db.Close(); err != nil {
			log.Printf("Error closing database: %v", err)
		}
	}()

	// Initialize Redis
	redisClient := redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Host + ":" + cfg.Redis.Port,
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})

	// Initialize JWT manager
	jwtManager := auth.NewJWTManager(cfg.JWT.Secret, cfg.JWT.AccessTokenTTL, cfg.JWT.RefreshTokenTTL)

	// Initialize WebSocket hub
	hub := websocket.NewHub()
	go hub.Run()

	// Initialize game engines
	registry := game.NewEngineRegistry()
	registry.Register(models.GameTypeDominoes, game.NewDominoEngine())
	registry.Register(models.GameTypeChess, game.NewChessEngine())

	// Initialize matchmaking service
	matchmaking := lobby.NewMatchmakingService(db, redisClient, registry)
	matchmaking.Start()

	// Setup routes
	router := api.SetupRoutes(db, jwtManager, hub)

	// Start server
	port := cfg.Server.Port
	if port == "" {
		port = "8181"
	}

	log.Printf("Starting server on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
