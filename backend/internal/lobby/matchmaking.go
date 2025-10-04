package lobby

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
	"github.com/szaher/vibeboard/backend/internal/database"
	"github.com/szaher/vibeboard/backend/internal/game"
	"github.com/szaher/vibeboard/backend/internal/models"
)

type MatchmakingService struct {
	db          *database.DB
	redisClient *redis.Client
	registry    *game.EngineRegistry
}

type MatchmakingRequest struct {
	UserID   uuid.UUID       `json:"user_id"`
	GameType models.GameType `json:"game_type"`
	Rating   int             `json:"rating"`
	JoinedAt time.Time       `json:"joined_at"`
}

type MatchResult struct {
	GameID    uuid.UUID       `json:"game_id"`
	Player1ID uuid.UUID       `json:"player1_id"`
	Player2ID uuid.UUID       `json:"player2_id"`
	GameType  models.GameType `json:"game_type"`
}

const (
	matchmakingQueueKey = "matchmaking:queue:%s" // game type
	matchmakingTimeout  = 5 * time.Minute
	ratingTolerance     = 100 // Initial rating tolerance
	maxRatingTolerance  = 500 // Maximum rating tolerance after waiting
)

func NewMatchmakingService(db *database.DB, redisClient *redis.Client, registry *game.EngineRegistry) *MatchmakingService {
	return &MatchmakingService{
		db:          db,
		redisClient: redisClient,
		registry:    registry,
	}
}

func (m *MatchmakingService) Start() {
	log.Println("Starting matchmaking service...")

	// Process matchmaking every 2 seconds
	ticker := time.NewTicker(2 * time.Second)
	go func() {
		for range ticker.C {
			m.processMatchmaking()
		}
	}()

	// Clean up expired requests every 30 seconds
	cleanupTicker := time.NewTicker(30 * time.Second)
	go func() {
		for range cleanupTicker.C {
			m.cleanupExpiredRequests()
		}
	}()
}

func (m *MatchmakingService) JoinQueue(userID uuid.UUID, gameType models.GameType, rating int) error {
	ctx := context.Background()
	queueKey := fmt.Sprintf(matchmakingQueueKey, gameType)

	// Check if user is already in queue
	exists, err := m.redisClient.ZScore(ctx, queueKey, userID.String()).Result()
	if err == nil && exists != 0 {
		return fmt.Errorf("user already in matchmaking queue")
	}

	request := MatchmakingRequest{
		UserID:   userID,
		GameType: gameType,
		Rating:   rating,
		JoinedAt: time.Now(),
	}

	requestData, err := json.Marshal(request)
	if err != nil {
		return fmt.Errorf("failed to marshal matchmaking request: %w", err)
	}

	// Add to sorted set with score as timestamp (for FIFO processing)
	score := float64(time.Now().Unix())
	err = m.redisClient.ZAdd(ctx, queueKey, redis.Z{
		Score:  score,
		Member: userID.String(),
	}).Err()
	if err != nil {
		return fmt.Errorf("failed to add to matchmaking queue: %w", err)
	}

	// Store request details
	requestKey := fmt.Sprintf("matchmaking:request:%s", userID)
	err = m.redisClient.Set(ctx, requestKey, requestData, matchmakingTimeout).Err()
	if err != nil {
		return fmt.Errorf("failed to store matchmaking request: %w", err)
	}

	log.Printf("User %s joined matchmaking queue for %s", userID, gameType)
	return nil
}

func (m *MatchmakingService) LeaveQueue(userID uuid.UUID, gameType models.GameType) error {
	ctx := context.Background()
	queueKey := fmt.Sprintf(matchmakingQueueKey, gameType)

	// Remove from queue
	err := m.redisClient.ZRem(ctx, queueKey, userID.String()).Err()
	if err != nil {
		return fmt.Errorf("failed to remove from matchmaking queue: %w", err)
	}

	// Remove request details
	requestKey := fmt.Sprintf("matchmaking:request:%s", userID)
	err = m.redisClient.Del(ctx, requestKey).Err()
	if err != nil {
		return fmt.Errorf("failed to remove matchmaking request: %w", err)
	}

	log.Printf("User %s left matchmaking queue for %s", userID, gameType)
	return nil
}

func (m *MatchmakingService) GetQueueStatus(userID uuid.UUID, gameType models.GameType) (*MatchmakingRequest, error) {
	ctx := context.Background()
	requestKey := fmt.Sprintf("matchmaking:request:%s", userID)

	requestData, err := m.redisClient.Get(ctx, requestKey).Result()
	if err == redis.Nil {
		return nil, fmt.Errorf("user not in matchmaking queue")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get matchmaking status: %w", err)
	}

	var request MatchmakingRequest
	err = json.Unmarshal([]byte(requestData), &request)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal matchmaking request: %w", err)
	}

	return &request, nil
}

func (m *MatchmakingService) processMatchmaking() {
	ctx := context.Background()

	// Process each game type
	for _, gameType := range m.registry.GetSupportedTypes() {
		queueKey := fmt.Sprintf(matchmakingQueueKey, gameType)

		// Get all users in queue (sorted by join time)
		userIDs, err := m.redisClient.ZRange(ctx, queueKey, 0, -1).Result()
		if err != nil {
			log.Printf("Error getting matchmaking queue for %s: %v", gameType, err)
			continue
		}

		if len(userIDs) < 2 {
			continue // Need at least 2 players
		}

		// Try to match players
		m.matchPlayers(gameType, userIDs)
	}
}

func (m *MatchmakingService) matchPlayers(gameType models.GameType, userIDs []string) {
	ctx := context.Background()

	for i := 0; i < len(userIDs)-1; i++ {
		player1ID := userIDs[i]
		player1Request, err := m.getMatchmakingRequest(player1ID)
		if err != nil {
			continue
		}

		// Calculate current rating tolerance based on wait time
		waitTime := time.Since(player1Request.JoinedAt)
		tolerance := m.calculateRatingTolerance(waitTime)

		// Find a suitable opponent
		for j := i + 1; j < len(userIDs); j++ {
			player2ID := userIDs[j]
			player2Request, err := m.getMatchmakingRequest(player2ID)
			if err != nil {
				continue
			}

			// Check if ratings are within tolerance
			ratingDiff := abs(player1Request.Rating - player2Request.Rating)
			if ratingDiff <= tolerance {
				// Create match
				err := m.createMatch(player1Request, player2Request)
				if err != nil {
					log.Printf("Failed to create match: %v", err)
					continue
				}

				// Remove both players from queue
				queueKey := fmt.Sprintf(matchmakingQueueKey, gameType)
				m.redisClient.ZRem(ctx, queueKey, player1ID, player2ID)

				// Remove request details
				m.redisClient.Del(ctx, fmt.Sprintf("matchmaking:request:%s", player1ID))
				m.redisClient.Del(ctx, fmt.Sprintf("matchmaking:request:%s", player2ID))

				log.Printf("Created match between %s and %s for %s", player1ID, player2ID, gameType)
				return
			}
		}
	}
}

func (m *MatchmakingService) createMatch(player1, player2 *MatchmakingRequest) error {
	// Get game engine
	engine, err := m.registry.GetEngine(player1.GameType)
	if err != nil {
		return fmt.Errorf("failed to get game engine: %w", err)
	}

	// Initialize game state
	initialState, err := engine.Initialize()
	if err != nil {
		return fmt.Errorf("failed to initialize game state: %w", err)
	}

	// Create game record
	game := &models.Game{
		ID:          uuid.New(),
		Type:        player1.GameType,
		Status:      models.GameStatusInProgress,
		Player1ID:   player1.UserID,
		Player2ID:   &player2.UserID,
		CurrentTurn: &player1.UserID, // Player 1 starts
		GameState:   initialState,
		StartedAt:   &[]time.Time{time.Now()}[0],
	}

	// Save game to database
	err = m.db.CreateGame(game)
	if err != nil {
		return fmt.Errorf("failed to create game: %w", err)
	}

	// TODO: Notify players via WebSocket that match was found
	// This would involve sending a message to both players with game details

	return nil
}

func (m *MatchmakingService) getMatchmakingRequest(userIDStr string) (*MatchmakingRequest, error) {
	ctx := context.Background()
	requestKey := fmt.Sprintf("matchmaking:request:%s", userIDStr)

	requestData, err := m.redisClient.Get(ctx, requestKey).Result()
	if err != nil {
		return nil, err
	}

	var request MatchmakingRequest
	err = json.Unmarshal([]byte(requestData), &request)
	if err != nil {
		return nil, err
	}

	return &request, nil
}

func (m *MatchmakingService) calculateRatingTolerance(waitTime time.Duration) int {
	// Start with base tolerance and increase over time
	tolerance := ratingTolerance + int(waitTime.Minutes())*20

	if tolerance > maxRatingTolerance {
		tolerance = maxRatingTolerance
	}

	return tolerance
}

func (m *MatchmakingService) cleanupExpiredRequests() {
	ctx := context.Background()

	for _, gameType := range m.registry.GetSupportedTypes() {
		queueKey := fmt.Sprintf(matchmakingQueueKey, gameType)

		// Get all users in queue
		userIDs, err := m.redisClient.ZRange(ctx, queueKey, 0, -1).Result()
		if err != nil {
			continue
		}

		expiredUsers := []string{}
		for _, userID := range userIDs {
			request, err := m.getMatchmakingRequest(userID)
			if err != nil || time.Since(request.JoinedAt) > matchmakingTimeout {
				expiredUsers = append(expiredUsers, userID)
			}
		}

		// Remove expired users
		if len(expiredUsers) > 0 {
			m.redisClient.ZRem(ctx, queueKey, expiredUsers)
			for _, userID := range expiredUsers {
				requestKey := fmt.Sprintf("matchmaking:request:%s", userID)
				m.redisClient.Del(ctx, requestKey)
			}
			log.Printf("Cleaned up %d expired matchmaking requests for %s", len(expiredUsers), gameType)
		}
	}
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}
