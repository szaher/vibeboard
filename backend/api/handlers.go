package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/szaher/mobile-game/backend/internal/auth"
	"github.com/szaher/mobile-game/backend/internal/database"
	"github.com/szaher/mobile-game/backend/internal/models"
)

type Handler struct {
	db         *database.DB
	jwtManager *auth.JWTManager
}

func NewHandler(db *database.DB, jwtManager *auth.JWTManager) *Handler {
	return &Handler{
		db:         db,
		jwtManager: jwtManager,
	}
}

// Auth handlers
type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Username string `json:"username" binding:"required,min=3,max=20"`
	Password string `json:"password" binding:"required,min=6"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if user already exists
	existingUser, _ := h.db.GetUserByEmail(req.Email)
	if existingUser != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "User already exists"})
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Create user
	user := &models.User{
		ID:       uuid.New(),
		Email:    req.Email,
		Username: req.Username,
		Password: string(hashedPassword),
		IsActive: true,
	}

	if err := h.db.CreateUser(user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	// Generate tokens
	tokens, err := h.jwtManager.GenerateTokenPair(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate tokens"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"user":   user,
		"tokens": tokens,
	})
}

func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get user by email
	user, err := h.db.GetUserByEmail(req.Email)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// Check password
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	if !user.IsActive {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Account is disabled"})
		return
	}

	// Generate tokens
	tokens, err := h.jwtManager.GenerateTokenPair(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate tokens"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"user":   user,
		"tokens": tokens,
	})
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

func (h *Handler) RefreshToken(c *gin.Context) {
	var req RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tokens, err := h.jwtManager.RefreshToken(req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid refresh token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"tokens": tokens})
}

// Game handlers
type CreateGameRequest struct {
	GameType string `json:"game_type" binding:"required"`
}

func (h *Handler) CreateGame(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	playerID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var req CreateGameRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	gameType := models.GameType(req.GameType)
	if gameType != models.GameTypeDominoes && gameType != models.GameTypeChess {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid game type"})
		return
	}

	game := &models.Game{
		ID:        uuid.New(),
		Type:      gameType,
		Status:    models.GameStatusWaiting,
		Player1ID: playerID,
	}

	if err := h.db.CreateGame(game); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create game"})
		return
	}

	c.JSON(http.StatusCreated, game)
}

func (h *Handler) JoinGame(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	playerID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	gameID, err := uuid.Parse(c.Param("gameId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid game ID"})
		return
	}

	game, err := h.db.GetGame(gameID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Game not found"})
		return
	}

	if game.Status != models.GameStatusWaiting {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Game is not waiting for players"})
		return
	}

	if game.Player1ID == playerID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot join your own game"})
		return
	}

	if game.Player2ID != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Game is already full"})
		return
	}

	game.Player2ID = &playerID
	game.Status = models.GameStatusInProgress

	if err := h.db.UpdateGame(game); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to join game"})
		return
	}

	c.JSON(http.StatusOK, game)
}

func (h *Handler) GetGame(c *gin.Context) {
	gameID, err := uuid.Parse(c.Param("gameId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid game ID"})
		return
	}

	game, err := h.db.GetGame(gameID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Game not found"})
		return
	}

	c.JSON(http.StatusOK, game)
}

func (h *Handler) GetGames(c *gin.Context) {
	status := c.Query("status")
	gameType := c.Query("type")

	limitStr := c.DefaultQuery("limit", "20")
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		limit = 20
	}

	offsetStr := c.DefaultQuery("offset", "0")
	offset, err := strconv.Atoi(offsetStr)
	if err != nil || offset < 0 {
		offset = 0
	}

	games, err := h.db.GetGames(status, gameType, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get games"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"games": games})
}

type MakeMoveRequest struct {
	MoveData interface{} `json:"move_data" binding:"required"`
}

func (h *Handler) MakeMove(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	playerID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	gameID, err := uuid.Parse(c.Param("gameId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid game ID"})
		return
	}

	var req MakeMoveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	game, err := h.db.GetGame(gameID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Game not found"})
		return
	}

	if game.Status != models.GameStatusInProgress {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Game is not in progress"})
		return
	}

	// Check if player is in the game
	if game.Player1ID != playerID && (game.Player2ID == nil || *game.Player2ID != playerID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Player not in this game"})
		return
	}

	// TODO: Validate and apply move using game engine
	// This would involve:
	// 1. Get the appropriate game engine
	// 2. Validate the move
	// 3. Apply the move
	// 4. Update game state
	// 5. Check for game end conditions

	c.JSON(http.StatusOK, gin.H{"message": "Move processing not yet implemented"})
}

// User handlers
func (h *Handler) GetProfile(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	user, err := h.db.GetUser(uid)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	stats, err := h.db.GetUserStats(uid)
	if err != nil {
		// If no stats exist, create empty stats
		stats = &models.UserStats{
			UserID:      uid,
			GamesPlayed: 0,
			GamesWon:    0,
			GamesLost:   0,
			Rating:      1000, // Default rating
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"user":  user,
		"stats": stats,
	})
}

// Health check
func (h *Handler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "vibe-arcade-backend",
		"version": "1.0.0",
	})
}
