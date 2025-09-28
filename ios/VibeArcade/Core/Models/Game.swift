import Foundation

// MARK: - Game Models
enum GameType: String, Codable, CaseIterable {
    case dominoes = "dominoes"
    case chess = "chess"

    var displayName: String {
        switch self {
        case .dominoes:
            return "Dominoes"
        case .chess:
            return "Chess"
        }
    }

    var icon: String {
        switch self {
        case .dominoes:
            return "square.grid.2x2"
        case .chess:
            return "crown"
        }
    }
}

enum GameStatus: String, Codable {
    case waiting = "waiting"
    case inProgress = "in_progress"
    case completed = "completed"
    case abandoned = "abandoned"

    var displayName: String {
        switch self {
        case .waiting:
            return "Waiting for player"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        case .abandoned:
            return "Abandoned"
        }
    }
}

struct Game: Codable, Identifiable {
    let id: UUID
    let type: GameType
    let status: GameStatus
    let player1Id: UUID
    let player2Id: UUID?
    let winnerId: UUID?
    let currentTurn: UUID?
    let gameState: Data
    let createdAt: Date
    let updatedAt: Date
    let startedAt: Date?
    let endedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, type, status
        case player1Id = "player1_id"
        case player2Id = "player2_id"
        case winnerId = "winner_id"
        case currentTurn = "current_turn"
        case gameState = "game_state"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case startedAt = "started_at"
        case endedAt = "ended_at"
    }

    var isWaitingForPlayer: Bool {
        return status == .waiting && player2Id == nil
    }

    func isPlayerTurn(_ playerId: UUID) -> Bool {
        return currentTurn == playerId
    }

    func getOpponentId(for playerId: UUID) -> UUID? {
        if playerId == player1Id {
            return player2Id
        } else if playerId == player2Id {
            return player1Id
        }
        return nil
    }
}

struct Move: Codable, Identifiable {
    let id: UUID
    let gameId: UUID
    let playerId: UUID
    let moveData: Data
    let createdAt: Date
    let isValid: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case playerId = "player_id"
        case moveData = "move_data"
        case createdAt = "created_at"
        case isValid = "is_valid"
    }
}

// MARK: - Game Creation/Management
struct CreateGameRequest: Codable {
    let gameType: String

    enum CodingKeys: String, CodingKey {
        case gameType = "game_type"
    }
}

struct MakeMoveRequest: Codable {
    let moveData: [String: Any]

    enum CodingKeys: String, CodingKey {
        case moveData = "move_data"
    }

    init(moveData: [String: Any]) {
        self.moveData = moveData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let data = try JSONSerialization.data(withJSONObject: moveData)
        let jsonString = String(data: data, encoding: .utf8) ?? "{}"
        try container.encode(jsonString, forKey: .moveData)
    }
}

struct GamesListResponse: Codable {
    let games: [Game]
}

// MARK: - WebSocket Messages
enum WebSocketMessageType: String, Codable {
    case joinRoom = "join_room"
    case leaveRoom = "leave_room"
    case gameMove = "game_move"
    case gameUpdate = "game_update"
    case chatMessage = "chat_message"
    case playerJoined = "player_joined"
    case playerLeft = "player_left"
    case error = "error"
    case heartbeat = "heartbeat"
}

struct WebSocketMessage: Codable {
    let type: WebSocketMessageType
    let roomId: String?
    let playerId: UUID
    let data: Data?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case type
        case roomId = "room_id"
        case playerId = "player_id"
        case data
        case timestamp
    }
}