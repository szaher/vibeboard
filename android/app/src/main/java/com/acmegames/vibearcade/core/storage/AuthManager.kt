package com.acmegames.vibearcade.core.storage

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import com.acmegames.vibearcade.core.models.*
import com.acmegames.vibearcade.core.networking.NetworkService
import com.acmegames.vibearcade.core.networking.handleResponse
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthManager constructor(
    private val dataStore: DataStore<Preferences>,
    private val networkService: dagger.Lazy<NetworkService>,
    private val gson: Gson
) {
    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()

    private val _currentUserStats = MutableStateFlow<UserStats?>(null)
    val currentUserStats: StateFlow<UserStats?> = _currentUserStats.asStateFlow()

    companion object {
        private val ACCESS_TOKEN_KEY = stringPreferencesKey("access_token")
        private val REFRESH_TOKEN_KEY = stringPreferencesKey("refresh_token")
        private val USER_KEY = stringPreferencesKey("user")
    }

    init {
        // Load stored authentication state
        CoroutineScope(Dispatchers.Main).launch {
            loadStoredAuth()
        }
    }

    private suspend fun loadStoredAuth() {
        val accessToken = getAccessToken()
        val storedUser = getStoredUser()

        if (!accessToken.isNullOrEmpty() && storedUser != null) {
            _currentUser.value = storedUser
            _isAuthenticated.value = true

            // Try to refresh profile in background
            try {
                loadProfile()
            } catch (e: Exception) {
                // If profile loading fails, we keep the stored user
            }
        }
    }

    suspend fun login(email: String, password: String): Result<Unit> {
        val request = LoginRequest(email, password)
        return try {
            val response = networkService.get().apiService.login(request).handleResponse()
            response.fold(
                onSuccess = { authResponse ->
                    handleAuthSuccess(authResponse)
                    Result.success(Unit)
                },
                onFailure = { Result.failure(it) }
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun register(email: String, username: String, password: String): Result<Unit> {
        val request = RegisterRequest(email, username, password)
        return try {
            val response = networkService.get().apiService.register(request).handleResponse()
            response.fold(
                onSuccess = { authResponse ->
                    handleAuthSuccess(authResponse)
                    Result.success(Unit)
                },
                onFailure = { Result.failure(it) }
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun refreshToken(): Boolean {
        val refreshToken = getRefreshToken() ?: return false

        return try {
            val request = RefreshTokenRequest(refreshToken)
            val response = networkService.get().apiService.refreshToken(request).handleResponse()
            response.fold(
                onSuccess = { tokenResponse ->
                    storeTokens(tokenResponse.tokens)
                    true
                },
                onFailure = { false }
            )
        } catch (e: Exception) {
            false
        }
    }

    suspend fun logout() {
        dataStore.edit { preferences ->
            preferences.clear()
        }
        _currentUser.value = null
        _currentUserStats.value = null
        _isAuthenticated.value = false
    }

    suspend fun loadProfile(): Result<ProfileResponse> {
        return try {
            val response = networkService.get().apiService.getProfile().handleResponse()
            response.fold(
                onSuccess = { profileResponse ->
                    _currentUser.value = profileResponse.user
                    _currentUserStats.value = profileResponse.stats
                    storeUser(profileResponse.user)
                    Result.success(profileResponse)
                },
                onFailure = { Result.failure(it) }
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Token management
    suspend fun getAccessToken(): String? {
        return dataStore.data.map { preferences ->
            preferences[ACCESS_TOKEN_KEY]
        }.first()
    }

    private suspend fun getRefreshToken(): String? {
        return dataStore.data.map { preferences ->
            preferences[REFRESH_TOKEN_KEY]
        }.first()
    }

    private suspend fun getStoredUser(): User? {
        val userJson = dataStore.data.map { preferences ->
            preferences[USER_KEY]
        }.first()
        return userJson?.let { gson.fromJson(it, User::class.java) }
    }

    private suspend fun handleAuthSuccess(authResponse: AuthResponse) {
        storeTokens(authResponse.tokens)
        storeUser(authResponse.user)
        _currentUser.value = authResponse.user
        _isAuthenticated.value = true
    }

    private suspend fun storeTokens(tokens: TokenPair) {
        dataStore.edit { preferences ->
            preferences[ACCESS_TOKEN_KEY] = tokens.accessToken
            preferences[REFRESH_TOKEN_KEY] = tokens.refreshToken
        }
    }

    private suspend fun storeUser(user: User) {
        dataStore.edit { preferences ->
            preferences[USER_KEY] = gson.toJson(user)
        }
    }

    fun getCurrentUserId(): String? = _currentUser.value?.id

    // Token validation
    suspend fun isTokenExpired(): Boolean {
        val token = getAccessToken() ?: return true

        return try {
            // Basic JWT parsing to check expiration
            val parts = token.split(".")
            if (parts.size != 3) return true

            val payload = parts[1]
            val decodedBytes = android.util.Base64.decode(addPadding(payload), android.util.Base64.URL_SAFE)
            val payloadJson = String(decodedBytes)

            val payloadMap = gson.fromJson(payloadJson, Map::class.java) as Map<String, Any>
            val exp = (payloadMap["exp"] as? Double)?.toLong() ?: return true

            val expirationTime = exp * 1000 // Convert to milliseconds
            System.currentTimeMillis() >= expirationTime
        } catch (e: Exception) {
            true
        }
    }

    private fun addPadding(base64String: String): String {
        val remainder = base64String.length % 4
        return if (remainder > 0) {
            base64String + "=".repeat(4 - remainder)
        } else {
            base64String
        }
    }

    suspend fun ensureValidToken(): Boolean {
        return if (isTokenExpired()) {
            refreshToken()
        } else {
            true
        }
    }
}