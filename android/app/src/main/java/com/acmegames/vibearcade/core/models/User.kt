package com.acmegames.vibearcade.core.models

import com.google.gson.annotations.SerializedName

// User Models
data class User(
    val id: String,
    val email: String,
    val username: String,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String,
    @SerializedName("is_active") val isActive: Boolean
)

data class UserStats(
    @SerializedName("user_id") val userId: String,
    @SerializedName("games_played") val gamesPlayed: Int,
    @SerializedName("games_won") val gamesWon: Int,
    @SerializedName("games_lost") val gamesLost: Int,
    val rating: Int,
    @SerializedName("updated_at") val updatedAt: String
) {
    val winRate: Double
        get() = if (gamesPlayed > 0) gamesWon.toDouble() / gamesPlayed.toDouble() else 0.0
}

// Authentication Models
data class LoginRequest(
    val email: String,
    val password: String
)

data class RegisterRequest(
    val email: String,
    val username: String,
    val password: String
)

data class TokenPair(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("refresh_token") val refreshToken: String
)

data class AuthResponse(
    val user: User,
    val tokens: TokenPair
)

data class TokenResponse(
    val tokens: TokenPair
)

data class RefreshTokenRequest(
    @SerializedName("refresh_token") val refreshToken: String
)

data class ProfileResponse(
    val user: User,
    val stats: UserStats
)