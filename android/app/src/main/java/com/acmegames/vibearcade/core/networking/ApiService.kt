package com.acmegames.vibearcade.core.networking

import com.acmegames.vibearcade.core.models.*
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    @POST(ApiConfiguration.Endpoints.REGISTER)
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>

    @POST(ApiConfiguration.Endpoints.LOGIN)
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>

    @POST(ApiConfiguration.Endpoints.REFRESH_TOKEN)
    suspend fun refreshToken(@Body request: RefreshTokenRequest): Response<TokenResponse>

    @GET(ApiConfiguration.Endpoints.PROFILE)
    suspend fun getProfile(): Response<ProfileResponse>

    @GET(ApiConfiguration.Endpoints.GAMES)
    suspend fun getGames(
        @Query("status") status: String? = null,
        @Query("type") type: String? = null,
        @Query("limit") limit: Int = 20,
        @Query("offset") offset: Int = 0
    ): Response<GamesListResponse>

    @POST(ApiConfiguration.Endpoints.CREATE_GAME)
    suspend fun createGame(@Body request: CreateGameRequest): Response<Game>

    @GET("games/{gameId}")
    suspend fun getGame(@Path("gameId") gameId: String): Response<Game>

    @POST("games/{gameId}/join")
    suspend fun joinGame(@Path("gameId") gameId: String): Response<Game>

    @POST("games/{gameId}/move")
    suspend fun makeMove(
        @Path("gameId") gameId: String,
        @Body request: MakeMoveRequest
    ): Response<Game>
}