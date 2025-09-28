package com.acmegames.vibearcade.core.networking

import com.acmegames.vibearcade.BuildConfig

object Environment {

    // Build configuration
    val isDebug: Boolean = BuildConfig.DEBUG
    val isProduction: Boolean = !isDebug

    // API Configuration
    val baseUrl: String = when {
        isDebug -> "http://10.0.2.2:8181/api/v1/"  // Android emulator localhost
        else -> "https://api.vibearcade.com/api/v1/"  // Production URL
    }

    val websocketUrl: String = when {
        isDebug -> "ws://10.0.2.2:8181/api/v1/ws"
        else -> "wss://api.vibearcade.com/api/v1/ws"
    }

    // Feature flags
    val enableLogging: Boolean = isDebug
    val enableDebugMenu: Boolean = isDebug

    // Network timeouts
    val connectTimeoutSeconds: Long = if (isDebug) 30 else 15
    val readTimeoutSeconds: Long = if (isDebug) 30 else 20
    val writeTimeoutSeconds: Long = if (isDebug) 30 else 20

    // Environment info
    val environmentName: String = if (isDebug) "development" else "production"

    // For manual override during development
    fun getCustomBaseUrl(): String? {
        // You can add SharedPreferences or build config field here
        // to allow runtime URL changes for testing different environments
        return null
    }

    fun getEffectiveBaseUrl(): String {
        return getCustomBaseUrl() ?: baseUrl
    }

    fun getEffectiveWebSocketUrl(): String {
        val customBase = getCustomBaseUrl()
        return if (customBase != null) {
            customBase.replace("http", "ws").replace("/api/v1/", "/api/v1/ws")
        } else {
            websocketUrl
        }
    }
}