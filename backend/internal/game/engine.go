package game

import (
	"encoding/json"
	"fmt"
	"github.com/google/uuid"
	"github.com/szaher/mobile-game/backend/internal/models"
)

type GameEngine interface {
	Initialize() (json.RawMessage, error)
	ValidateMove(gameState json.RawMessage, move json.RawMessage, playerID uuid.UUID) error
	ApplyMove(gameState json.RawMessage, move json.RawMessage, playerID uuid.UUID) (json.RawMessage, error)
	GetGameStatus(gameState json.RawMessage) GameStatusInfo
	GetPossibleMoves(gameState json.RawMessage, playerID uuid.UUID) ([]json.RawMessage, error)
	GetGameType() models.GameType
}

type GameStatusInfo struct {
	IsGameOver bool
	Winner     *uuid.UUID
	NextPlayer *uuid.UUID
	IsDraw     bool
}

type EngineRegistry struct {
	engines map[models.GameType]GameEngine
}

func NewEngineRegistry() *EngineRegistry {
	return &EngineRegistry{
		engines: make(map[models.GameType]GameEngine),
	}
}

func (r *EngineRegistry) Register(gameType models.GameType, engine GameEngine) {
	r.engines[gameType] = engine
}

func (r *EngineRegistry) GetEngine(gameType models.GameType) (GameEngine, error) {
	engine, exists := r.engines[gameType]
	if !exists {
		return nil, fmt.Errorf("game engine not found for type: %s", gameType)
	}
	return engine, nil
}

func (r *EngineRegistry) GetSupportedTypes() []models.GameType {
	types := make([]models.GameType, 0, len(r.engines))
	for gameType := range r.engines {
		types = append(types, gameType)
	}
	return types
}

var GlobalRegistry = NewEngineRegistry()
