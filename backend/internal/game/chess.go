package game

import (
	"encoding/json"
	"errors"
	"github.com/google/uuid"
	"github.com/szaher/mobile-game/backend/internal/models"
)

type ChessPiece struct {
	Type  string `json:"type"`  // "pawn", "rook", "knight", "bishop", "queen", "king"
	Color string `json:"color"` // "white", "black"
}

type ChessPosition struct {
	Row int `json:"row"` // 0-7
	Col int `json:"col"` // 0-7
}

type ChessGameState struct {
	Board       [8][8]*ChessPiece `json:"board"`
	CurrentTurn string            `json:"current_turn"` // "white", "black"
	Player1ID   uuid.UUID         `json:"player1_id"`
	Player2ID   uuid.UUID         `json:"player2_id"`
	WhitePlayer uuid.UUID         `json:"white_player"`
	BlackPlayer uuid.UUID         `json:"black_player"`
	GameEnded   bool              `json:"game_ended"`
	Winner      *uuid.UUID        `json:"winner,omitempty"`
	Check       bool              `json:"check"`
	Checkmate   bool              `json:"checkmate"`
	Stalemate   bool              `json:"stalemate"`
	// Castling rights
	WhiteKingSideCastle  bool `json:"white_king_side_castle"`
	WhiteQueenSideCastle bool `json:"white_queen_side_castle"`
	BlackKingSideCastle  bool `json:"black_king_side_castle"`
	BlackQueenSideCastle bool `json:"black_queen_side_castle"`
	// En passant
	EnPassantTarget *ChessPosition `json:"en_passant_target,omitempty"`
	MoveCount       int            `json:"move_count"`
}

type ChessMove struct {
	From      ChessPosition `json:"from"`
	To        ChessPosition `json:"to"`
	Promotion string        `json:"promotion,omitempty"` // For pawn promotion
	Castling  string        `json:"castling,omitempty"`  // "king_side" or "queen_side"
}

type ChessEngine struct{}

func NewChessEngine() *ChessEngine {
	return &ChessEngine{}
}

func (e *ChessEngine) GetGameType() models.GameType {
	return models.GameTypeChess
}

func (e *ChessEngine) Initialize() (json.RawMessage, error) {
	gameState := ChessGameState{
		CurrentTurn:          "white",
		GameEnded:            false,
		WhiteKingSideCastle:  true,
		WhiteQueenSideCastle: true,
		BlackKingSideCastle:  true,
		BlackQueenSideCastle: true,
		MoveCount:            0,
	}

	// Initialize the chess board
	e.setupInitialBoard(&gameState)

	stateBytes, err := json.Marshal(gameState)
	return json.RawMessage(stateBytes), err
}

func (e *ChessEngine) ValidateMove(gameState json.RawMessage, move json.RawMessage, playerID uuid.UUID) error {
	var state ChessGameState
	if err := json.Unmarshal(gameState, &state); err != nil {
		return err
	}

	var chessMove ChessMove
	if err := json.Unmarshal(move, &chessMove); err != nil {
		return err
	}

	// Check if it's player's turn
	playerColor := e.getPlayerColor(state, playerID)
	if playerColor != state.CurrentTurn {
		return errors.New("not player's turn")
	}

	// Check if game has ended
	if state.GameEnded {
		return errors.New("game has already ended")
	}

	// Validate the move
	return e.validateChessMove(state, chessMove, playerColor)
}

func (e *ChessEngine) ApplyMove(gameState json.RawMessage, move json.RawMessage, playerID uuid.UUID) (json.RawMessage, error) {
	var state ChessGameState
	if err := json.Unmarshal(gameState, &state); err != nil {
		return nil, err
	}

	var chessMove ChessMove
	if err := json.Unmarshal(move, &chessMove); err != nil {
		return nil, err
	}

	playerColor := e.getPlayerColor(state, playerID)

	// Apply the move
	e.applyChessMove(&state, chessMove, playerColor)

	// Switch turns
	if state.CurrentTurn == "white" {
		state.CurrentTurn = "black"
	} else {
		state.CurrentTurn = "white"
	}

	state.MoveCount++

	// Check for game ending conditions
	e.updateGameStatus(&state)

	stateBytes, err := json.Marshal(state)
	return json.RawMessage(stateBytes), err
}

func (e *ChessEngine) GetGameStatus(gameState json.RawMessage) GameStatusInfo {
	var state ChessGameState
	if err := json.Unmarshal(gameState, &state); err != nil {
		return GameStatusInfo{}
	}

	var nextPlayer *uuid.UUID
	if !state.GameEnded {
		if state.CurrentTurn == "white" {
			nextPlayer = &state.WhitePlayer
		} else {
			nextPlayer = &state.BlackPlayer
		}
	}

	return GameStatusInfo{
		IsGameOver: state.GameEnded,
		Winner:     state.Winner,
		NextPlayer: nextPlayer,
		IsDraw:     state.GameEnded && state.Winner == nil,
	}
}

func (e *ChessEngine) GetPossibleMoves(gameState json.RawMessage, playerID uuid.UUID) ([]json.RawMessage, error) {
	var state ChessGameState
	if err := json.Unmarshal(gameState, &state); err != nil {
		return nil, err
	}

	playerColor := e.getPlayerColor(state, playerID)
	var possibleMoves []json.RawMessage

	// Generate all possible moves for the player
	for row := 0; row < 8; row++ {
		for col := 0; col < 8; col++ {
			piece := state.Board[row][col]
			if piece != nil && piece.Color == playerColor {
				moves := e.generatePieceMoves(state, ChessPosition{Row: row, Col: col})
				for _, move := range moves {
					if e.validateChessMove(state, move, playerColor) == nil {
						moveBytes, _ := json.Marshal(move)
						possibleMoves = append(possibleMoves, json.RawMessage(moveBytes))
					}
				}
			}
		}
	}

	return possibleMoves, nil
}

// Helper functions
func (e *ChessEngine) setupInitialBoard(state *ChessGameState) {
	// Initialize empty board
	for i := 0; i < 8; i++ {
		for j := 0; j < 8; j++ {
			state.Board[i][j] = nil
		}
	}

	// Place pawns
	for i := 0; i < 8; i++ {
		state.Board[1][i] = &ChessPiece{Type: "pawn", Color: "black"}
		state.Board[6][i] = &ChessPiece{Type: "pawn", Color: "white"}
	}

	// Place other pieces
	pieceOrder := []string{"rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"}
	for i, pieceType := range pieceOrder {
		state.Board[0][i] = &ChessPiece{Type: pieceType, Color: "black"}
		state.Board[7][i] = &ChessPiece{Type: pieceType, Color: "white"}
	}
}

func (e *ChessEngine) getPlayerColor(state ChessGameState, playerID uuid.UUID) string {
	if playerID == state.WhitePlayer {
		return "white"
	}
	return "black"
}

func (e *ChessEngine) validateChessMove(state ChessGameState, move ChessMove, playerColor string) error {
	// Basic boundary checks
	if !e.isValidPosition(move.From) || !e.isValidPosition(move.To) {
		return errors.New("invalid position")
	}

	fromPiece := state.Board[move.From.Row][move.From.Col]
	if fromPiece == nil {
		return errors.New("no piece at source position")
	}

	if fromPiece.Color != playerColor {
		return errors.New("cannot move opponent's piece")
	}

	toPiece := state.Board[move.To.Row][move.To.Col]
	if toPiece != nil && toPiece.Color == playerColor {
		return errors.New("cannot capture own piece")
	}

	// Validate piece-specific move rules
	return e.validatePieceMove(state, move, fromPiece)
}

func (e *ChessEngine) validatePieceMove(state ChessGameState, move ChessMove, piece *ChessPiece) error {
	switch piece.Type {
	case "pawn":
		return e.validatePawnMove(state, move, piece.Color)
	case "rook":
		return e.validateRookMove(state, move)
	case "knight":
		return e.validateKnightMove(move)
	case "bishop":
		return e.validateBishopMove(state, move)
	case "queen":
		return e.validateQueenMove(state, move)
	case "king":
		return e.validateKingMove(move)
	default:
		return errors.New("unknown piece type")
	}
}

func (e *ChessEngine) validatePawnMove(state ChessGameState, move ChessMove, color string) error {
	direction := 1
	startRow := 6
	if color == "black" {
		direction = -1
		startRow = 1
	}

	rowDiff := move.To.Row - move.From.Row
	colDiff := move.To.Col - move.From.Col

	// Forward move
	if colDiff == 0 {
		if rowDiff == direction && state.Board[move.To.Row][move.To.Col] == nil {
			return nil
		}
		if rowDiff == 2*direction && move.From.Row == startRow &&
			state.Board[move.To.Row][move.To.Col] == nil &&
			state.Board[move.From.Row+direction][move.From.Col] == nil {
			return nil
		}
	}

	// Diagonal capture
	if abs(colDiff) == 1 && rowDiff == direction {
		targetPiece := state.Board[move.To.Row][move.To.Col]
		if targetPiece != nil && targetPiece.Color != color {
			return nil
		}
		// En passant
		if state.EnPassantTarget != nil &&
			move.To.Row == state.EnPassantTarget.Row &&
			move.To.Col == state.EnPassantTarget.Col {
			return nil
		}
	}

	return errors.New("invalid pawn move")
}

func (e *ChessEngine) validateRookMove(state ChessGameState, move ChessMove) error {
	if move.From.Row != move.To.Row && move.From.Col != move.To.Col {
		return errors.New("rook must move in straight line")
	}
	return e.checkPathClear(state, move.From, move.To)
}

func (e *ChessEngine) validateKnightMove(move ChessMove) error {
	rowDiff := abs(move.To.Row - move.From.Row)
	colDiff := abs(move.To.Col - move.From.Col)
	if (rowDiff == 2 && colDiff == 1) || (rowDiff == 1 && colDiff == 2) {
		return nil
	}
	return errors.New("invalid knight move")
}

func (e *ChessEngine) validateBishopMove(state ChessGameState, move ChessMove) error {
	rowDiff := abs(move.To.Row - move.From.Row)
	colDiff := abs(move.To.Col - move.From.Col)
	if rowDiff != colDiff {
		return errors.New("bishop must move diagonally")
	}
	return e.checkPathClear(state, move.From, move.To)
}

func (e *ChessEngine) validateQueenMove(state ChessGameState, move ChessMove) error {
	// Queen moves like rook or bishop
	if e.validateRookMove(state, move) == nil || e.validateBishopMove(state, move) == nil {
		return nil
	}
	return errors.New("invalid queen move")
}

func (e *ChessEngine) validateKingMove(move ChessMove) error {
	rowDiff := abs(move.To.Row - move.From.Row)
	colDiff := abs(move.To.Col - move.From.Col)
	if rowDiff <= 1 && colDiff <= 1 && (rowDiff != 0 || colDiff != 0) {
		return nil
	}
	return errors.New("invalid king move")
}

func (e *ChessEngine) checkPathClear(state ChessGameState, from, to ChessPosition) error {
	rowDir := 0
	colDir := 0

	if to.Row > from.Row {
		rowDir = 1
	} else if to.Row < from.Row {
		rowDir = -1
	}

	if to.Col > from.Col {
		colDir = 1
	} else if to.Col < from.Col {
		colDir = -1
	}

	currentRow := from.Row + rowDir
	currentCol := from.Col + colDir

	for currentRow != to.Row || currentCol != to.Col {
		if state.Board[currentRow][currentCol] != nil {
			return errors.New("path is blocked")
		}
		currentRow += rowDir
		currentCol += colDir
	}

	return nil
}

func (e *ChessEngine) applyChessMove(state *ChessGameState, move ChessMove, playerColor string) {
	// Move the piece
	piece := state.Board[move.From.Row][move.From.Col]
	state.Board[move.To.Row][move.To.Col] = piece
	state.Board[move.From.Row][move.From.Col] = nil

	// Handle pawn promotion
	if piece.Type == "pawn" && (move.To.Row == 0 || move.To.Row == 7) {
		if move.Promotion != "" {
			piece.Type = move.Promotion
		} else {
			piece.Type = "queen" // Default promotion
		}
	}

	// Handle en passant target
	state.EnPassantTarget = nil
	if piece.Type == "pawn" && abs(move.To.Row-move.From.Row) == 2 {
		state.EnPassantTarget = &ChessPosition{
			Row: (move.From.Row + move.To.Row) / 2,
			Col: move.From.Col,
		}
	}

	// Update castling rights
	if piece.Type == "king" {
		if playerColor == "white" {
			state.WhiteKingSideCastle = false
			state.WhiteQueenSideCastle = false
		} else {
			state.BlackKingSideCastle = false
			state.BlackQueenSideCastle = false
		}
	}
	if piece.Type == "rook" {
		if move.From.Row == 0 && move.From.Col == 0 {
			state.BlackQueenSideCastle = false
		} else if move.From.Row == 0 && move.From.Col == 7 {
			state.BlackKingSideCastle = false
		} else if move.From.Row == 7 && move.From.Col == 0 {
			state.WhiteQueenSideCastle = false
		} else if move.From.Row == 7 && move.From.Col == 7 {
			state.WhiteKingSideCastle = false
		}
	}
}

func (e *ChessEngine) updateGameStatus(state *ChessGameState) {
	// Simplified game status update - in a full implementation,
	// you would check for check, checkmate, and stalemate
	// For now, we'll just check if the king is captured (simplified)

	whiteKingExists := false
	blackKingExists := false

	for row := 0; row < 8; row++ {
		for col := 0; col < 8; col++ {
			piece := state.Board[row][col]
			if piece != nil && piece.Type == "king" {
				if piece.Color == "white" {
					whiteKingExists = true
				} else {
					blackKingExists = true
				}
			}
		}
	}

	if !whiteKingExists {
		state.GameEnded = true
		state.Winner = &state.BlackPlayer
	} else if !blackKingExists {
		state.GameEnded = true
		state.Winner = &state.WhitePlayer
	}
}

func (e *ChessEngine) generatePieceMoves(state ChessGameState, pos ChessPosition) []ChessMove {
	var moves []ChessMove
	piece := state.Board[pos.Row][pos.Col]

	// Simplified move generation - generate basic moves for each piece type
	switch piece.Type {
	case "pawn":
		moves = e.generatePawnMoves(state, pos, piece.Color)
	case "rook":
		moves = e.generateRookMoves(pos)
	case "knight":
		moves = e.generateKnightMoves(pos)
	case "bishop":
		moves = e.generateBishopMoves(pos)
	case "queen":
		moves = e.generateQueenMoves(pos)
	case "king":
		moves = e.generateKingMoves(pos)
	}

	return moves
}

func (e *ChessEngine) generatePawnMoves(state ChessGameState, pos ChessPosition, color string) []ChessMove {
	var moves []ChessMove
	direction := 1
	if color == "black" {
		direction = -1
	}

	// Forward moves
	newRow := pos.Row + direction
	if e.isValidPosition(ChessPosition{Row: newRow, Col: pos.Col}) {
		moves = append(moves, ChessMove{From: pos, To: ChessPosition{Row: newRow, Col: pos.Col}})
	}

	// Diagonal captures
	for _, colOffset := range []int{-1, 1} {
		newCol := pos.Col + colOffset
		if e.isValidPosition(ChessPosition{Row: newRow, Col: newCol}) {
			moves = append(moves, ChessMove{From: pos, To: ChessPosition{Row: newRow, Col: newCol}})
		}
	}

	return moves
}

func (e *ChessEngine) generateRookMoves(pos ChessPosition) []ChessMove {
	var moves []ChessMove
	directions := [][]int{{0, 1}, {0, -1}, {1, 0}, {-1, 0}}

	for _, dir := range directions {
		for i := 1; i < 8; i++ {
			newRow := pos.Row + dir[0]*i
			newCol := pos.Col + dir[1]*i
			if !e.isValidPosition(ChessPosition{Row: newRow, Col: newCol}) {
				break
			}
			moves = append(moves, ChessMove{From: pos, To: ChessPosition{Row: newRow, Col: newCol}})
		}
	}

	return moves
}

func (e *ChessEngine) generateKnightMoves(pos ChessPosition) []ChessMove {
	var moves []ChessMove
	knightMoves := [][]int{{2, 1}, {2, -1}, {-2, 1}, {-2, -1}, {1, 2}, {1, -2}, {-1, 2}, {-1, -2}}

	for _, move := range knightMoves {
		newRow := pos.Row + move[0]
		newCol := pos.Col + move[1]
		if e.isValidPosition(ChessPosition{Row: newRow, Col: newCol}) {
			moves = append(moves, ChessMove{From: pos, To: ChessPosition{Row: newRow, Col: newCol}})
		}
	}

	return moves
}

func (e *ChessEngine) generateBishopMoves(pos ChessPosition) []ChessMove {
	var moves []ChessMove
	directions := [][]int{{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}

	for _, dir := range directions {
		for i := 1; i < 8; i++ {
			newRow := pos.Row + dir[0]*i
			newCol := pos.Col + dir[1]*i
			if !e.isValidPosition(ChessPosition{Row: newRow, Col: newCol}) {
				break
			}
			moves = append(moves, ChessMove{From: pos, To: ChessPosition{Row: newRow, Col: newCol}})
		}
	}

	return moves
}

func (e *ChessEngine) generateQueenMoves(pos ChessPosition) []ChessMove {
	var moves []ChessMove
	moves = append(moves, e.generateRookMoves(pos)...)
	moves = append(moves, e.generateBishopMoves(pos)...)
	return moves
}

func (e *ChessEngine) generateKingMoves(pos ChessPosition) []ChessMove {
	var moves []ChessMove
	directions := [][]int{{0, 1}, {0, -1}, {1, 0}, {-1, 0}, {1, 1}, {1, -1}, {-1, 1}, {-1, -1}}

	for _, dir := range directions {
		newRow := pos.Row + dir[0]
		newCol := pos.Col + dir[1]
		if e.isValidPosition(ChessPosition{Row: newRow, Col: newCol}) {
			moves = append(moves, ChessMove{From: pos, To: ChessPosition{Row: newRow, Col: newCol}})
		}
	}

	return moves
}

func (e *ChessEngine) isValidPosition(pos ChessPosition) bool {
	return pos.Row >= 0 && pos.Row < 8 && pos.Col >= 0 && pos.Col < 8
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}
