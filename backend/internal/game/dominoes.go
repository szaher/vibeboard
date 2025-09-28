package game

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/google/uuid"
	"github.com/szaher/mobile-game/backend/internal/models"
	"math/rand"
)

type DominoTile struct {
	Left  int `json:"left"`
	Right int `json:"right"`
}

type DominoGameState struct {
	PlayerHands map[uuid.UUID][]DominoTile `json:"player_hands"`
	Board       []DominoTile               `json:"board"`
	BoneYard    []DominoTile               `json:"bone_yard"`
	CurrentTurn uuid.UUID                  `json:"current_turn"`
	Player1ID   uuid.UUID                  `json:"player1_id"`
	Player2ID   uuid.UUID                  `json:"player2_id"`
	GameEnded   bool                       `json:"game_ended"`
	Winner      *uuid.UUID                 `json:"winner,omitempty"`
}

type DominoMove struct {
	Tile DominoTile `json:"tile"`
	Side string     `json:"side"` // "left" or "right"
	Pass bool       `json:"pass"` // true if player passes turn
}

type DominoEngine struct{}

func NewDominoEngine() *DominoEngine {
	return &DominoEngine{}
}

func (e *DominoEngine) GetGameType() models.GameType {
	return models.GameTypeDominoes
}

func (e *DominoEngine) Initialize() (json.RawMessage, error) {
	tiles := e.generateDominoSet()

	shuffledTiles := make([]DominoTile, len(tiles))
	copy(shuffledTiles, tiles)
	rand.Shuffle(len(shuffledTiles), func(i, j int) {
		shuffledTiles[i], shuffledTiles[j] = shuffledTiles[j], shuffledTiles[i]
	})

	gameState := DominoGameState{
		PlayerHands: make(map[uuid.UUID][]DominoTile),
		Board:       []DominoTile{},
		BoneYard:    shuffledTiles[14:], // Remaining tiles after dealing
		GameEnded:   false,
	}

	// Each player gets 7 tiles
	for i := 0; i < 7; i++ {
		gameState.PlayerHands[gameState.Player1ID] = append(gameState.PlayerHands[gameState.Player1ID], shuffledTiles[i])
		gameState.PlayerHands[gameState.Player2ID] = append(gameState.PlayerHands[gameState.Player2ID], shuffledTiles[i+7])
	}

	// Player with highest double starts, or highest tile value
	starter := e.determineStartingPlayer(gameState)
	gameState.CurrentTurn = starter

	stateBytes, err := json.Marshal(gameState)
	return json.RawMessage(stateBytes), err
}

func (e *DominoEngine) ValidateMove(gameState json.RawMessage, move json.RawMessage, playerID uuid.UUID) error {
	var state DominoGameState
	if err := json.Unmarshal(gameState, &state); err != nil {
		return err
	}

	var domMove DominoMove
	if err := json.Unmarshal(move, &domMove); err != nil {
		return err
	}

	// Check if it's player's turn
	if state.CurrentTurn != playerID {
		return errors.New("not player's turn")
	}

	// Check if game has ended
	if state.GameEnded {
		return errors.New("game has already ended")
	}

	// If passing, check if player can actually play
	if domMove.Pass {
		canPlay := e.canPlayerPlay(state, playerID)
		if canPlay {
			return errors.New("player must play if possible")
		}
		return nil
	}

	// Check if player has the tile
	playerHand := state.PlayerHands[playerID]
	hasTile := false
	for _, tile := range playerHand {
		if (tile.Left == domMove.Tile.Left && tile.Right == domMove.Tile.Right) ||
			(tile.Left == domMove.Tile.Right && tile.Right == domMove.Tile.Left) {
			hasTile = true
			break
		}
	}
	if !hasTile {
		return errors.New("player doesn't have this tile")
	}

	// If board is empty, any tile is valid (first move)
	if len(state.Board) == 0 {
		return nil
	}

	// Check if tile can be placed on the specified side
	return e.validateTilePlacement(state.Board, domMove.Tile, domMove.Side)
}

func (e *DominoEngine) ApplyMove(gameState json.RawMessage, move json.RawMessage, playerID uuid.UUID) (json.RawMessage, error) {
	var state DominoGameState
	if err := json.Unmarshal(gameState, &state); err != nil {
		return nil, err
	}

	var domMove DominoMove
	if err := json.Unmarshal(move, &domMove); err != nil {
		return nil, err
	}

	if domMove.Pass {
		// Switch turns
		state.CurrentTurn = e.getOtherPlayer(state, playerID)

		// Check if both players passed (game blocked)
		if !e.canPlayerPlay(state, state.CurrentTurn) {
			state.GameEnded = true
			winner := e.determineWinnerByScore(state)
			state.Winner = winner
		}
	} else {
		// Remove tile from player's hand
		playerHand := state.PlayerHands[playerID]
		for i, tile := range playerHand {
			if (tile.Left == domMove.Tile.Left && tile.Right == domMove.Tile.Right) ||
				(tile.Left == domMove.Tile.Right && tile.Right == domMove.Tile.Left) {
				state.PlayerHands[playerID] = append(playerHand[:i], playerHand[i+1:]...)
				break
			}
		}

		// Add tile to board
		if len(state.Board) == 0 {
			state.Board = append(state.Board, domMove.Tile)
		} else {
			e.placeTileOnBoard(&state.Board, domMove.Tile, domMove.Side)
		}

		// Check if player won (no tiles left)
		if len(state.PlayerHands[playerID]) == 0 {
			state.GameEnded = true
			state.Winner = &playerID
		} else {
			// Switch turns
			state.CurrentTurn = e.getOtherPlayer(state, playerID)
		}
	}

	stateBytes, err := json.Marshal(state)
	return json.RawMessage(stateBytes), err
}

func (e *DominoEngine) GetGameStatus(gameState json.RawMessage) GameStatusInfo {
	var state DominoGameState
	if err := json.Unmarshal(gameState, &state); err != nil {
		return GameStatusInfo{}
	}

	return GameStatusInfo{
		IsGameOver: state.GameEnded,
		Winner:     state.Winner,
		NextPlayer: &state.CurrentTurn,
		IsDraw:     state.GameEnded && state.Winner == nil,
	}
}

func (e *DominoEngine) GetPossibleMoves(gameState json.RawMessage, playerID uuid.UUID) ([]json.RawMessage, error) {
	var state DominoGameState
	if err := json.Unmarshal(gameState, &state); err != nil {
		return nil, err
	}

	var possibleMoves []json.RawMessage
	playerHand := state.PlayerHands[playerID]

	// If board is empty, any tile can be played
	if len(state.Board) == 0 {
		for _, tile := range playerHand {
			move := DominoMove{Tile: tile, Side: "left"}
			moveBytes, _ := json.Marshal(move)
			possibleMoves = append(possibleMoves, json.RawMessage(moveBytes))
		}
		return possibleMoves, nil
	}

	// Check each tile in hand
	for _, tile := range playerHand {
		// Try left side
		if e.validateTilePlacement(state.Board, tile, "left") == nil {
			move := DominoMove{Tile: tile, Side: "left"}
			moveBytes, _ := json.Marshal(move)
			possibleMoves = append(possibleMoves, json.RawMessage(moveBytes))
		}
		// Try right side
		if e.validateTilePlacement(state.Board, tile, "right") == nil {
			move := DominoMove{Tile: tile, Side: "right"}
			moveBytes, _ := json.Marshal(move)
			possibleMoves = append(possibleMoves, json.RawMessage(moveBytes))
		}
	}

	// If no moves possible, add pass option
	if len(possibleMoves) == 0 {
		passMove := DominoMove{Pass: true}
		moveBytes, _ := json.Marshal(passMove)
		possibleMoves = append(possibleMoves, json.RawMessage(moveBytes))
	}

	return possibleMoves, nil
}

// Helper functions
func (e *DominoEngine) generateDominoSet() []DominoTile {
	var tiles []DominoTile
	for i := 0; i <= 6; i++ {
		for j := i; j <= 6; j++ {
			tiles = append(tiles, DominoTile{Left: i, Right: j})
		}
	}
	return tiles
}

func (e *DominoEngine) determineStartingPlayer(state DominoGameState) uuid.UUID {
	// Player with highest double starts, or highest tile value
	p1Max := e.getHighestTileValue(state.PlayerHands[state.Player1ID])
	p2Max := e.getHighestTileValue(state.PlayerHands[state.Player2ID])

	if p1Max >= p2Max {
		return state.Player1ID
	}
	return state.Player2ID
}

func (e *DominoEngine) getHighestTileValue(hand []DominoTile) int {
	maxValue := -1
	for _, tile := range hand {
		value := tile.Left + tile.Right
		if tile.Left == tile.Right { // Double tile gets priority
			value += 100
		}
		if value > maxValue {
			maxValue = value
		}
	}
	return maxValue
}

func (e *DominoEngine) canPlayerPlay(state DominoGameState, playerID uuid.UUID) bool {
	if len(state.Board) == 0 {
		return true
	}

	playerHand := state.PlayerHands[playerID]
	leftEnd := state.Board[0].Left
	rightEnd := state.Board[len(state.Board)-1].Right

	for _, tile := range playerHand {
		if tile.Left == leftEnd || tile.Right == leftEnd ||
			tile.Left == rightEnd || tile.Right == rightEnd {
			return true
		}
	}
	return false
}

func (e *DominoEngine) validateTilePlacement(board []DominoTile, tile DominoTile, side string) error {
	if side == "left" {
		leftEnd := board[0].Left
		if tile.Left != leftEnd && tile.Right != leftEnd {
			return fmt.Errorf("tile doesn't match left end of board")
		}
	} else if side == "right" {
		rightEnd := board[len(board)-1].Right
		if tile.Left != rightEnd && tile.Right != rightEnd {
			return fmt.Errorf("tile doesn't match right end of board")
		}
	} else {
		return fmt.Errorf("invalid side: must be 'left' or 'right'")
	}
	return nil
}

func (e *DominoEngine) placeTileOnBoard(board *[]DominoTile, tile DominoTile, side string) {
	if side == "left" {
		leftEnd := (*board)[0].Left
		if tile.Right == leftEnd {
			*board = append([]DominoTile{tile}, *board...)
		} else {
			// Flip tile
			flipped := DominoTile{Left: tile.Right, Right: tile.Left}
			*board = append([]DominoTile{flipped}, *board...)
		}
	} else {
		rightEnd := (*board)[len(*board)-1].Right
		if tile.Left == rightEnd {
			*board = append(*board, tile)
		} else {
			// Flip tile
			flipped := DominoTile{Left: tile.Right, Right: tile.Left}
			*board = append(*board, flipped)
		}
	}
}

func (e *DominoEngine) getOtherPlayer(state DominoGameState, playerID uuid.UUID) uuid.UUID {
	if playerID == state.Player1ID {
		return state.Player2ID
	}
	return state.Player1ID
}

func (e *DominoEngine) determineWinnerByScore(state DominoGameState) *uuid.UUID {
	p1Score := e.calculateHandScore(state.PlayerHands[state.Player1ID])
	p2Score := e.calculateHandScore(state.PlayerHands[state.Player2ID])

	if p1Score < p2Score {
		return &state.Player1ID
	} else if p2Score < p1Score {
		return &state.Player2ID
	}
	return nil // Draw
}

func (e *DominoEngine) calculateHandScore(hand []DominoTile) int {
	score := 0
	for _, tile := range hand {
		score += tile.Left + tile.Right
	}
	return score
}
