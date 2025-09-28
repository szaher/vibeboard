package com.acmegames.vibearcade.core.models

import com.google.gson.annotations.SerializedName

// Game Models
enum class GameType(val value: String, val displayName: String, val subtitle: String) {
    DOMINOES("dominoes", "Dominoes", "Classic tile-matching game"),
    CHESS("chess", "Chess", "Strategic board game");

    companion object {
        fun fromString(value: String): GameType? {
            return values().find { it.value == value }
        }
    }
}

enum class GameStatus(val value: String, val displayName: String) {
    WAITING("waiting", "Waiting for player"),
    IN_PROGRESS("in_progress", "In progress"),
    COMPLETED("completed", "Completed"),
    ABANDONED("abandoned", "Abandoned");

    companion object {
        fun fromString(value: String): GameStatus? {
            return values().find { it.value == value }
        }
    }
}

data class Game(
    val id: String,
    val type: String,
    val status: String,
    @SerializedName("player1_id") val player1Id: String,
    @SerializedName("player2_id") val player2Id: String?,
    @SerializedName("winner_id") val winnerId: String?,
    @SerializedName("current_turn") val currentTurn: String?,
    @SerializedName("game_state") val gameState: String,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String,
    @SerializedName("started_at") val startedAt: String?,
    @SerializedName("ended_at") val endedAt: String?
) {
    val gameType: GameType?
        get() = GameType.fromString(type)

    val gameStatus: GameStatus?
        get() = GameStatus.fromString(status)

    val isWaitingForPlayer: Boolean
        get() = status == "waiting" && player2Id == null

    fun isPlayerTurn(playerId: String): Boolean = currentTurn == playerId

    fun getOpponentId(playerId: String): String? {
        return when (playerId) {
            player1Id -> player2Id
            player2Id -> player1Id
            else -> null
        }
    }
}

data class Move(
    val id: String,
    @SerializedName("game_id") val gameId: String,
    @SerializedName("player_id") val playerId: String,
    @SerializedName("move_data") val moveData: String,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("is_valid") val isValid: Boolean
)

// Game Management
data class CreateGameRequest(
    @SerializedName("game_type") val gameType: String
)

data class MakeMoveRequest(
    @SerializedName("move_data") val moveData: Any
)

data class GamesListResponse(
    val games: List<Game>
)

// WebSocket Messages
data class WebSocketMessage(
    val type: String,
    @SerializedName("room_id") val roomId: String?,
    @SerializedName("player_id") val playerId: String,
    val data: String?,
    val timestamp: Long
)