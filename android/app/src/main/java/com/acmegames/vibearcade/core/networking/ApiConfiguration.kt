package com.acmegames.vibearcade.core.networking

object ApiConfiguration {
    val BASE_URL = Environment.getEffectiveBaseUrl()
    val WEBSOCKET_URL = Environment.getEffectiveWebSocketUrl()

    // Endpoints
    object Endpoints {
        const val REGISTER = "auth/register"
        const val LOGIN = "auth/login"
        const val REFRESH_TOKEN = "auth/refresh"
        const val PROFILE = "user/profile"
        const val GAMES = "games"
        const val CREATE_GAME = "games"

        fun joinGame(gameId: String) = "games/$gameId/join"
        fun gameDetails(gameId: String) = "games/$gameId"
        fun makeMove(gameId: String) = "games/$gameId/move"
    }

    // Headers
    const val CONTENT_TYPE = "application/json"
    const val AUTHORIZATION = "Authorization"
    const val BEARER = "Bearer "
}