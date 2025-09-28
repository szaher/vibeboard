package com.acmegames.vibearcade

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.acmegames.vibearcade.features.auth.AuthScreen
import com.acmegames.vibearcade.features.lobby.LobbyScreen
import com.acmegames.vibearcade.core.storage.AuthManager
import com.acmegames.vibearcade.ui.theme.VibeArcadeTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var authManager: AuthManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            VibeArcadeTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    VibeArcadeApp(authManager = authManager)
                }
            }
        }
    }
}

@Composable
fun VibeArcadeApp(authManager: AuthManager) {
    val navController = rememberNavController()
    val isAuthenticated = authManager.isAuthenticated.collectAsStateWithLifecycle()

    NavHost(
        navController = navController,
        startDestination = if (isAuthenticated.value) "lobby" else "auth"
    ) {
        composable("auth") {
            AuthScreen(
                onAuthSuccess = {
                    navController.navigate("lobby") {
                        popUpTo("auth") { inclusive = true }
                    }
                }
            )
        }

        composable("lobby") {
            LobbyScreen(
                onLogout = {
                    navController.navigate("auth") {
                        popUpTo("lobby") { inclusive = true }
                    }
                }
            )
        }
    }
}