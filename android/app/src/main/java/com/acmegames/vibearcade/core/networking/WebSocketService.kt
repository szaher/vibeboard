package com.acmegames.vibearcade.core.networking

import com.acmegames.vibearcade.core.models.WebSocketMessage
import com.acmegames.vibearcade.core.storage.AuthManager
import com.google.gson.Gson
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WebSocketService @Inject constructor(
    private val authManager: AuthManager
) {
    private val gson = Gson()
    private var webSocket: WebSocket? = null
    private val messagesChannel = Channel<WebSocketMessage>(Channel.UNLIMITED)

    private val _connectionState = MutableStateFlow(WebSocketConnectionState.DISCONNECTED)
    val connectionState: StateFlow<WebSocketConnectionState> = _connectionState.asStateFlow()

    private val _lastError = MutableStateFlow<String?>(null)
    val lastError: StateFlow<String?> = _lastError.asStateFlow()

    val messages: Flow<WebSocketMessage> = messagesChannel.receiveAsFlow()

    private val client = OkHttpClient.Builder().build()

    suspend fun connect() {
        if (_connectionState.value == WebSocketConnectionState.CONNECTED ||
            _connectionState.value == WebSocketConnectionState.CONNECTING) {
            return
        }

        val token = authManager.getAccessToken()
        if (token.isNullOrEmpty()) {
            _lastError.value = "No authentication token available"
            return
        }

        _connectionState.value = WebSocketConnectionState.CONNECTING

        val request = Request.Builder()
            .url(ApiConfiguration.WEBSOCKET_URL)
            .header("Authorization", "Bearer $token")
            .build()

        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                _connectionState.value = WebSocketConnectionState.CONNECTED
                _lastError.value = null
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                try {
                    val message = gson.fromJson(text, WebSocketMessage::class.java)
                    messagesChannel.trySend(message)
                } catch (e: Exception) {
                    _lastError.value = "Failed to parse message: ${e.message}"
                }
            }

            override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
                try {
                    val text = bytes.utf8()
                    val message = gson.fromJson(text, WebSocketMessage::class.java)
                    messagesChannel.trySend(message)
                } catch (e: Exception) {
                    _lastError.value = "Failed to parse message: ${e.message}"
                }
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                _connectionState.value = WebSocketConnectionState.DISCONNECTED
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                _connectionState.value = WebSocketConnectionState.DISCONNECTED
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                _connectionState.value = WebSocketConnectionState.DISCONNECTED
                _lastError.value = t.message
            }
        })
    }

    fun disconnect() {
        webSocket?.close(1000, "Normal closure")
        webSocket = null
        _connectionState.value = WebSocketConnectionState.DISCONNECTED
    }

    fun sendMessage(message: WebSocketMessage) {
        if (_connectionState.value != WebSocketConnectionState.CONNECTED) {
            _lastError.value = "WebSocket not connected"
            return
        }

        try {
            val json = gson.toJson(message)
            webSocket?.send(json)
        } catch (e: Exception) {
            _lastError.value = "Failed to send message: ${e.message}"
        }
    }

    // Convenience methods
    fun joinRoom(roomId: String) {
        val playerId = authManager.getCurrentUserId() ?: return
        val message = WebSocketMessage(
            type = "join_room",
            roomId = roomId,
            playerId = playerId,
            data = null,
            timestamp = System.currentTimeMillis()
        )
        sendMessage(message)
    }

    fun leaveRoom(roomId: String) {
        val playerId = authManager.getCurrentUserId() ?: return
        val message = WebSocketMessage(
            type = "leave_room",
            roomId = roomId,
            playerId = playerId,
            data = null,
            timestamp = System.currentTimeMillis()
        )
        sendMessage(message)
    }

    fun sendGameMove(roomId: String, moveData: Any) {
        val playerId = authManager.getCurrentUserId() ?: return
        val message = WebSocketMessage(
            type = "game_move",
            roomId = roomId,
            playerId = playerId,
            data = gson.toJson(moveData),
            timestamp = System.currentTimeMillis()
        )
        sendMessage(message)
    }

    fun sendChatMessage(roomId: String, text: String) {
        val playerId = authManager.getCurrentUserId() ?: return
        val chatData = mapOf("message" to text)
        val message = WebSocketMessage(
            type = "chat_message",
            roomId = roomId,
            playerId = playerId,
            data = gson.toJson(chatData),
            timestamp = System.currentTimeMillis()
        )
        sendMessage(message)
    }
}

enum class WebSocketConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED
}