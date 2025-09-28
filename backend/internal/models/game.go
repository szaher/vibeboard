package models

import (
	"encoding/json"
	"github.com/google/uuid"
	"time"
)

type GameType string

const (
	GameTypeDominoes GameType = "dominoes"
	GameTypeChess    GameType = "chess"
)

type GameStatus string

const (
	GameStatusWaiting    GameStatus = "waiting"
	GameStatusInProgress GameStatus = "in_progress"
	GameStatusCompleted  GameStatus = "completed"
	GameStatusAbandoned  GameStatus = "abandoned"
)

type Game struct {
	ID          uuid.UUID       `json:"id" db:"id"`
	Type        GameType        `json:"type" db:"game_type"`
	Status      GameStatus      `json:"status" db:"status"`
	Player1ID   uuid.UUID       `json:"player1_id" db:"player1_id"`
	Player2ID   *uuid.UUID      `json:"player2_id,omitempty" db:"player2_id"`
	WinnerID    *uuid.UUID      `json:"winner_id,omitempty" db:"winner_id"`
	CurrentTurn *uuid.UUID      `json:"current_turn,omitempty" db:"current_turn"`
	GameState   json.RawMessage `json:"game_state" db:"game_state"`
	CreatedAt   time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at" db:"updated_at"`
	StartedAt   *time.Time      `json:"started_at,omitempty" db:"started_at"`
	EndedAt     *time.Time      `json:"ended_at,omitempty" db:"ended_at"`
}

type Move struct {
	ID        uuid.UUID       `json:"id" db:"id"`
	GameID    uuid.UUID       `json:"game_id" db:"game_id"`
	PlayerID  uuid.UUID       `json:"player_id" db:"player_id"`
	MoveData  json.RawMessage `json:"move_data" db:"move_data"`
	CreatedAt time.Time       `json:"created_at" db:"created_at"`
	IsValid   bool            `json:"is_valid" db:"is_valid"`
}

type GameRoom struct {
	ID         string      `json:"id"`
	GameID     uuid.UUID   `json:"game_id"`
	Players    []uuid.UUID `json:"players"`
	Spectators []uuid.UUID `json:"spectators"`
	CreatedAt  time.Time   `json:"created_at"`
}
