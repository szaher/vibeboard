package api

import (
	"github.com/gin-gonic/gin"
	"github.com/szaher/mobile-game/backend/internal/auth"
	"github.com/szaher/mobile-game/backend/internal/database"
	"github.com/szaher/mobile-game/backend/internal/websocket"
)

func SetupRoutes(db *database.DB, jwtManager *auth.JWTManager, hub *websocket.Hub) *gin.Engine {
	router := gin.Default()

	// Middleware
	router.Use(CORSMiddleware())
	router.Use(RateLimitMiddleware())

	// Initialize handler
	handler := NewHandler(db, jwtManager)

	// Health check
	router.GET("/health", handler.HealthCheck)

	// API routes
	api := router.Group("/api/v1")
	{
		// Auth routes (no authentication required)
		auth := api.Group("/auth")
		{
			auth.POST("/register", handler.Register)
			auth.POST("/login", handler.Login)
			auth.POST("/refresh", handler.RefreshToken)
		}

		// Protected routes
		protected := api.Group("")
		protected.Use(AuthMiddleware(jwtManager))
		{
			// User routes
			user := protected.Group("/user")
			{
				user.GET("/profile", handler.GetProfile)
			}

			// Game routes
			games := protected.Group("/games")
			{
				games.POST("/", handler.CreateGame)
				games.GET("/", handler.GetGames)
				games.GET("/:gameId", handler.GetGame)
				games.POST("/:gameId/join", handler.JoinGame)
				games.POST("/:gameId/move", handler.MakeMove)
			}

			// WebSocket endpoint
			protected.GET("/ws", hub.HandleWebSocket)
		}
	}

	return router
}
