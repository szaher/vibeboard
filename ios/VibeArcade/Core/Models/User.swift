import Foundation

// MARK: - User Models
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let username: String
    let createdAt: Date
    let updatedAt: Date
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, username
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isActive = "is_active"
    }
}

struct UserStats: Codable {
    let userId: UUID
    let gamesPlayed: Int
    let gamesWon: Int
    let gamesLost: Int
    let rating: Int
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case gamesPlayed = "games_played"
        case gamesWon = "games_won"
        case gamesLost = "games_lost"
        case rating
        case updatedAt = "updated_at"
    }

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
}

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let username: String
    let password: String
}

struct TokenPair: Codable {
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

struct AuthResponse: Codable {
    let user: User
    let tokens: TokenPair
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct ProfileResponse: Codable {
    let user: User
    let stats: UserStats
}