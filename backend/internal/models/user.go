package models

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID        uuid.UUID `json:"id" db:"id"`
	Email     string    `json:"email" db:"email"`
	Username  string    `json:"username" db:"username"`
	Password  string    `json:"-" db:"password_hash"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	IsActive  bool      `json:"is_active" db:"is_active"`
}

type UserStats struct {
	UserID      uuid.UUID `json:"user_id" db:"user_id"`
	GamesPlayed int       `json:"games_played" db:"games_played"`
	GamesWon    int       `json:"games_won" db:"games_won"`
	GamesLost   int       `json:"games_lost" db:"games_lost"`
	Rating      int       `json:"rating" db:"rating"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}
