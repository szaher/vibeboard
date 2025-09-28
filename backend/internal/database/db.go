package database

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
	"github.com/szaher/vibeboard/backend/internal/models"
	"github.com/szaher/vibeboard/backend/pkg/config"
)

type DB struct {
	conn *sql.DB
}

func NewDB(cfg *config.DatabaseConfig) (*DB, error) {
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.Name, cfg.SSLMode)

	conn, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	if err := conn.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &DB{conn: conn}, nil
}

func (db *DB) Close() error {
	return db.conn.Close()
}

// User operations
func (db *DB) CreateUser(user *models.User) error {
	query := `
		INSERT INTO users (id, email, username, password_hash, created_at, updated_at, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, $7)`

	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now

	_, err := db.conn.Exec(query, user.ID, user.Email, user.Username, user.Password, user.CreatedAt, user.UpdatedAt, user.IsActive)
	return err
}

func (db *DB) GetUser(id uuid.UUID) (*models.User, error) {
	query := `
		SELECT id, email, username, password_hash, created_at, updated_at, is_active
		FROM users WHERE id = $1`

	user := &models.User{}
	err := db.conn.QueryRow(query, id).Scan(
		&user.ID, &user.Email, &user.Username, &user.Password,
		&user.CreatedAt, &user.UpdatedAt, &user.IsActive,
	)

	if err != nil {
		return nil, err
	}

	return user, nil
}

func (db *DB) GetUserByEmail(email string) (*models.User, error) {
	query := `
		SELECT id, email, username, password_hash, created_at, updated_at, is_active
		FROM users WHERE email = $1`

	user := &models.User{}
	err := db.conn.QueryRow(query, email).Scan(
		&user.ID, &user.Email, &user.Username, &user.Password,
		&user.CreatedAt, &user.UpdatedAt, &user.IsActive,
	)

	if err != nil {
		return nil, err
	}

	return user, nil
}

func (db *DB) UpdateUser(user *models.User) error {
	query := `
		UPDATE users SET email = $2, username = $3, password_hash = $4, updated_at = $5, is_active = $6
		WHERE id = $1`

	user.UpdatedAt = time.Now()
	_, err := db.conn.Exec(query, user.ID, user.Email, user.Username, user.Password, user.UpdatedAt, user.IsActive)
	return err
}

// User stats operations
func (db *DB) GetUserStats(userID uuid.UUID) (*models.UserStats, error) {
	query := `
		SELECT user_id, games_played, games_won, games_lost, rating, updated_at
		FROM user_stats WHERE user_id = $1`

	stats := &models.UserStats{}
	err := db.conn.QueryRow(query, userID).Scan(
		&stats.UserID, &stats.GamesPlayed, &stats.GamesWon, &stats.GamesLost,
		&stats.Rating, &stats.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return stats, nil
}

func (db *DB) UpdateUserStats(stats *models.UserStats) error {
	query := `
		INSERT INTO user_stats (user_id, games_played, games_won, games_lost, rating, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (user_id) DO UPDATE SET
			games_played = EXCLUDED.games_played,
			games_won = EXCLUDED.games_won,
			games_lost = EXCLUDED.games_lost,
			rating = EXCLUDED.rating,
			updated_at = EXCLUDED.updated_at`

	stats.UpdatedAt = time.Now()
	_, err := db.conn.Exec(query, stats.UserID, stats.GamesPlayed, stats.GamesWon, stats.GamesLost, stats.Rating, stats.UpdatedAt)
	return err
}

// Game operations
func (db *DB) CreateGame(game *models.Game) error {
	query := `
		INSERT INTO games (id, game_type, status, player1_id, player2_id, winner_id, current_turn, game_state, created_at, updated_at, started_at, ended_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`

	now := time.Now()
	game.CreatedAt = now
	game.UpdatedAt = now

	_, err := db.conn.Exec(query, game.ID, game.Type, game.Status, game.Player1ID, game.Player2ID, game.WinnerID, game.CurrentTurn, game.GameState, game.CreatedAt, game.UpdatedAt, game.StartedAt, game.EndedAt)
	return err
}

func (db *DB) GetGame(id uuid.UUID) (*models.Game, error) {
	query := `
		SELECT id, game_type, status, player1_id, player2_id, winner_id, current_turn, game_state, created_at, updated_at, started_at, ended_at
		FROM games WHERE id = $1`

	game := &models.Game{}
	err := db.conn.QueryRow(query, id).Scan(
		&game.ID, &game.Type, &game.Status, &game.Player1ID, &game.Player2ID,
		&game.WinnerID, &game.CurrentTurn, &game.GameState, &game.CreatedAt,
		&game.UpdatedAt, &game.StartedAt, &game.EndedAt,
	)

	if err != nil {
		return nil, err
	}

	return game, nil
}

func (db *DB) UpdateGame(game *models.Game) error {
	query := `
		UPDATE games SET game_type = $2, status = $3, player1_id = $4, player2_id = $5, winner_id = $6,
		current_turn = $7, game_state = $8, updated_at = $9, started_at = $10, ended_at = $11
		WHERE id = $1`

	game.UpdatedAt = time.Now()
	_, err := db.conn.Exec(query, game.ID, game.Type, game.Status, game.Player1ID, game.Player2ID, game.WinnerID, game.CurrentTurn, game.GameState, game.UpdatedAt, game.StartedAt, game.EndedAt)
	return err
}

func (db *DB) GetGames(status, gameType string, limit, offset int) ([]*models.Game, error) {
	query := `
		SELECT id, game_type, status, player1_id, player2_id, winner_id, current_turn, game_state, created_at, updated_at, started_at, ended_at
		FROM games`

	args := []interface{}{}
	conditions := []string{}
	argIndex := 1

	if status != "" {
		conditions = append(conditions, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, status)
		argIndex++
	}

	if gameType != "" {
		conditions = append(conditions, fmt.Sprintf("game_type = $%d", argIndex))
		args = append(args, gameType)
		argIndex++
	}

	if len(conditions) > 0 {
		query += " WHERE " + fmt.Sprintf("%s", conditions[0])
		for i := 1; i < len(conditions); i++ {
			query += " AND " + conditions[i]
		}
	}

	query += fmt.Sprintf(" ORDER BY created_at DESC LIMIT $%d OFFSET $%d", argIndex, argIndex+1)
	args = append(args, limit, offset)

	rows, err := db.conn.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var games []*models.Game
	for rows.Next() {
		game := &models.Game{}
		err := rows.Scan(
			&game.ID, &game.Type, &game.Status, &game.Player1ID, &game.Player2ID,
			&game.WinnerID, &game.CurrentTurn, &game.GameState, &game.CreatedAt,
			&game.UpdatedAt, &game.StartedAt, &game.EndedAt,
		)
		if err != nil {
			return nil, err
		}
		games = append(games, game)
	}

	return games, nil
}

// Move operations
func (db *DB) CreateMove(move *models.Move) error {
	query := `
		INSERT INTO moves (id, game_id, player_id, move_data, created_at, is_valid)
		VALUES ($1, $2, $3, $4, $5, $6)`

	move.CreatedAt = time.Now()
	_, err := db.conn.Exec(query, move.ID, move.GameID, move.PlayerID, move.MoveData, move.CreatedAt, move.IsValid)
	return err
}

func (db *DB) GetGameMoves(gameID uuid.UUID) ([]*models.Move, error) {
	query := `
		SELECT id, game_id, player_id, move_data, created_at, is_valid
		FROM moves WHERE game_id = $1 ORDER BY created_at ASC`

	rows, err := db.conn.Query(query, gameID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var moves []*models.Move
	for rows.Next() {
		move := &models.Move{}
		err := rows.Scan(&move.ID, &move.GameID, &move.PlayerID, &move.MoveData, &move.CreatedAt, &move.IsValid)
		if err != nil {
			return nil, err
		}
		moves = append(moves, move)
	}

	return moves, nil
}
