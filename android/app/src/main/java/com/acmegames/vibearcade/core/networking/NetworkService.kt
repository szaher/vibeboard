package com.acmegames.vibearcade.core.networking

import com.acmegames.vibearcade.core.storage.AuthManager
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NetworkService @Inject constructor(
    private val authManager: AuthManager
) {
    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val authInterceptor = Interceptor { chain ->
        val originalRequest = chain.request()

        // Skip auth for login/register endpoints
        val skipAuth = originalRequest.url.encodedPath.contains("auth/")

        if (skipAuth) {
            chain.proceed(originalRequest)
        } else {
            val token = runBlocking { authManager.getAccessToken() }
            val newRequest = originalRequest.newBuilder()
                .header(ApiConfiguration.AUTHORIZATION, "${ApiConfiguration.BEARER}$token")
                .build()
            chain.proceed(newRequest)
        }
    }

    private val tokenRefreshInterceptor = Interceptor { chain ->
        val response = chain.proceed(chain.request())

        if (response.code == 401) {
            response.close()

            // Try to refresh token
            val refreshed = runBlocking { authManager.refreshToken() }

            if (refreshed) {
                // Retry with new token
                val token = runBlocking { authManager.getAccessToken() }
                val newRequest = chain.request().newBuilder()
                    .header(ApiConfiguration.AUTHORIZATION, "${ApiConfiguration.BEARER}$token")
                    .build()
                chain.proceed(newRequest)
            } else {
                // Logout user
                runBlocking { authManager.logout() }
                response
            }
        } else {
            response
        }
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .addInterceptor(authInterceptor)
        .addInterceptor(tokenRefreshInterceptor)
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl(ApiConfiguration.BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    val apiService: ApiService = retrofit.create(ApiService::class.java)
}

// Extension function for handling API responses
suspend fun <T> Response<T>.handleResponse(): Result<T> {
    return try {
        if (isSuccessful) {
            body()?.let { Result.success(it) } ?: Result.failure(Exception("Empty response body"))
        } else {
            Result.failure(NetworkException(code(), message()))
        }
    } catch (e: Exception) {
        Result.failure(e)
    }
}

class NetworkException(val code: Int, message: String) : Exception("HTTP $code: $message")