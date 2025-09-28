package com.acmegames.vibearcade.core.models

import com.google.gson.annotations.SerializedName

// Dominoes Game Models
data class DominoTile(
    val left: Int,
    val right: Int
) {
    val isDouble: Boolean
        get() = left == right

    val value: Int
        get() = left + right

    fun canConnect(value: Int): Boolean = left == value || right == value

    fun flipped(): DominoTile = DominoTile(right, left)
}

data class DominoGameState(
    @SerializedName("player_hands") val playerHands: Map<String, List<DominoTile>>,
    val board: List<DominoTile>,
    @SerializedName("bone_yard") val boneYard: List<DominoTile>,
    @SerializedName("current_turn") val currentTurn: String,
    @SerializedName("player1_id") val player1Id: String,
    @SerializedName("player2_id") val player2Id: String,
    @SerializedName("game_ended") val gameEnded: Boolean,
    val winner: String?
) {
    fun getPlayerHand(playerId: String): List<DominoTile> = playerHands[playerId] ?: emptyList()

    val boardLeftValue: Int?
        get() = board.firstOrNull()?.left

    val boardRightValue: Int?
        get() = board.lastOrNull()?.right
}

data class DominoMove(
    val tile: DominoTile,
    val side: String, // "left" or "right"
    val pass: Boolean = false
) {
    companion object {
        fun pass(): DominoMove = DominoMove(DominoTile(0, 0), "", true)
    }
}

// Chess Game Models
data class ChessPiece(
    val type: String, // "pawn", "rook", "knight", "bishop", "queen", "king"
    val color: String // "white", "black"
) {
    val symbol: String
        get() = when (color to type) {
            "white" to "king" -> "♔"
            "white" to "queen" -> "♕"
            "white" to "rook" -> "♖"
            "white" to "bishop" -> "♗"
            "white" to "knight" -> "♘"
            "white" to "pawn" -> "♙"
            "black" to "king" -> "♚"
            "black" to "queen" -> "♛"
            "black" to "rook" -> "♜"
            "black" to "bishop" -> "♝"
            "black" to "knight" -> "♞"
            "black" to "pawn" -> "♟"
            else -> "?"
        }
}

data class ChessPosition(
    val row: Int,
    val col: Int
) {
    val isValid: Boolean
        get() = row in 0..7 && col in 0..7

    fun notation(): String {
        val files = listOf("a", "b", "c", "d", "e", "f", "g", "h")
        val ranks = listOf("1", "2", "3", "4", "5", "6", "7", "8")
        return if (col < files.size && row < ranks.size) {
            files[col] + ranks[row]
        } else ""
    }
}

data class ChessGameState(
    val board: List<List<ChessPiece?>>,
    @SerializedName("current_turn") val currentTurn: String,
    @SerializedName("player1_id") val player1Id: String,
    @SerializedName("player2_id") val player2Id: String,
    @SerializedName("white_player") val whitePlayer: String,
    @SerializedName("black_player") val blackPlayer: String,
    @SerializedName("game_ended") val gameEnded: Boolean,
    val winner: String?,
    val check: Boolean,
    val checkmate: Boolean,
    val stalemate: Boolean,
    @SerializedName("white_king_side_castle") val whiteKingSideCastle: Boolean,
    @SerializedName("white_queen_side_castle") val whiteQueenSideCastle: Boolean,
    @SerializedName("black_king_side_castle") val blackKingSideCastle: Boolean,
    @SerializedName("black_queen_side_castle") val blackQueenSideCastle: Boolean,
    @SerializedName("en_passant_target") val enPassantTarget: ChessPosition?,
    @SerializedName("move_count") val moveCount: Int
) {
    fun getPiece(position: ChessPosition): ChessPiece? {
        return if (position.isValid) board[position.row][position.col] else null
    }

    fun getPlayerColor(playerId: String): String? {
        return when (playerId) {
            whitePlayer -> "white"
            blackPlayer -> "black"
            else -> null
        }
    }
}

data class ChessMove(
    val from: ChessPosition,
    val to: ChessPosition,
    val promotion: String? = null,
    val castling: String? = null
)