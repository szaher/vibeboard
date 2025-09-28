package com.acmegames.vibearcade.core.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import com.acmegames.vibearcade.core.networking.NetworkService
import com.acmegames.vibearcade.core.networking.WebSocketService
import com.acmegames.vibearcade.core.storage.AuthManager
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "vibe_arcade_prefs")

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideGson(): Gson {
        return GsonBuilder()
            .setLenient()
            .create()
    }

    @Provides
    @Singleton
    fun provideDataStore(@ApplicationContext context: Context): DataStore<Preferences> {
        return context.dataStore
    }

    @Provides
    @Singleton
    fun provideAuthManager(
        dataStore: DataStore<Preferences>,
        networkService: NetworkService,
        gson: Gson
    ): AuthManager {
        return AuthManager(dataStore, networkService, gson)
    }

    @Provides
    @Singleton
    fun provideNetworkService(authManager: AuthManager): NetworkService {
        return NetworkService(authManager)
    }

    @Provides
    @Singleton
    fun provideWebSocketService(authManager: AuthManager): WebSocketService {
        return WebSocketService(authManager)
    }
}