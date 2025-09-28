package com.acmegames.vibearcade.features.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.acmegames.vibearcade.core.storage.AuthManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authManager: AuthManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            authManager.isAuthenticated.collect { isAuthenticated ->
                _uiState.value = _uiState.value.copy(isAuthenticated = isAuthenticated)
            }
        }
    }

    fun updateEmail(email: String) {
        _uiState.value = _uiState.value.copy(email = email, errorMessage = null)
    }

    fun updateUsername(username: String) {
        _uiState.value = _uiState.value.copy(username = username, errorMessage = null)
    }

    fun updatePassword(password: String) {
        _uiState.value = _uiState.value.copy(password = password, errorMessage = null)
    }

    fun updateConfirmPassword(confirmPassword: String) {
        _uiState.value = _uiState.value.copy(confirmPassword = confirmPassword, errorMessage = null)
    }

    fun switchToLogin() {
        _uiState.value = _uiState.value.copy(
            isLogin = true,
            errorMessage = null,
            username = "",
            confirmPassword = ""
        )
    }

    fun switchToRegister() {
        _uiState.value = _uiState.value.copy(
            isLogin = false,
            errorMessage = null
        )
    }

    fun login() {
        val currentState = _uiState.value

        if (!validateLoginInput(currentState)) return

        viewModelScope.launch {
            _uiState.value = currentState.copy(isLoading = true, errorMessage = null)

            authManager.login(currentState.email, currentState.password)
                .fold(
                    onSuccess = {
                        _uiState.value = currentState.copy(isLoading = false)
                    },
                    onFailure = { error ->
                        _uiState.value = currentState.copy(
                            isLoading = false,
                            errorMessage = error.message ?: "Login failed"
                        )
                    }
                )
        }
    }

    fun register() {
        val currentState = _uiState.value

        if (!validateRegisterInput(currentState)) return

        viewModelScope.launch {
            _uiState.value = currentState.copy(isLoading = true, errorMessage = null)

            authManager.register(currentState.email, currentState.username, currentState.password)
                .fold(
                    onSuccess = {
                        _uiState.value = currentState.copy(isLoading = false)
                    },
                    onFailure = { error ->
                        _uiState.value = currentState.copy(
                            isLoading = false,
                            errorMessage = error.message ?: "Registration failed"
                        )
                    }
                )
        }
    }

    private fun validateLoginInput(state: AuthUiState): Boolean {
        when {
            state.email.isBlank() -> {
                _uiState.value = state.copy(errorMessage = "Please enter your email")
                return false
            }
            !android.util.Patterns.EMAIL_ADDRESS.matcher(state.email).matches() -> {
                _uiState.value = state.copy(errorMessage = "Please enter a valid email address")
                return false
            }
            state.password.isBlank() -> {
                _uiState.value = state.copy(errorMessage = "Please enter your password")
                return false
            }
        }
        return true
    }

    private fun validateRegisterInput(state: AuthUiState): Boolean {
        when {
            state.email.isBlank() -> {
                _uiState.value = state.copy(errorMessage = "Please enter your email")
                return false
            }
            !android.util.Patterns.EMAIL_ADDRESS.matcher(state.email).matches() -> {
                _uiState.value = state.copy(errorMessage = "Please enter a valid email address")
                return false
            }
            state.username.isBlank() -> {
                _uiState.value = state.copy(errorMessage = "Please enter a username")
                return false
            }
            state.username.length < 3 -> {
                _uiState.value = state.copy(errorMessage = "Username must be at least 3 characters")
                return false
            }
            state.password.isBlank() -> {
                _uiState.value = state.copy(errorMessage = "Please enter a password")
                return false
            }
            state.password.length < 6 -> {
                _uiState.value = state.copy(errorMessage = "Password must be at least 6 characters")
                return false
            }
            state.confirmPassword.isBlank() -> {
                _uiState.value = state.copy(errorMessage = "Please confirm your password")
                return false
            }
            state.password != state.confirmPassword -> {
                _uiState.value = state.copy(errorMessage = "Passwords do not match")
                return false
            }
        }
        return true
    }
}

data class AuthUiState(
    val isLogin: Boolean = true,
    val email: String = "",
    val username: String = "",
    val password: String = "",
    val confirmPassword: String = "",
    val isLoading: Boolean = false,
    val isAuthenticated: Boolean = false,
    val errorMessage: String? = null
)