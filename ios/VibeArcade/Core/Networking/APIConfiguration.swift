import Foundation

struct APIConfiguration {
    static let shared = APIConfiguration()

    private init() {}

    // MARK: - Base Configuration
    let baseURL = Environment.shared.baseURL
    let websocketURL = Environment.shared.websocketURL

    // MARK: - Endpoints
    enum Endpoint {
        case register
        case login
        case refreshToken
        case profile
        case games
        case createGame
        case joinGame(String)
        case gameDetails(String)
        case makeMove(String)

        var path: String {
            switch self {
            case .register:
                return "/auth/register"
            case .login:
                return "/auth/login"
            case .refreshToken:
                return "/auth/refresh"
            case .profile:
                return "/user/profile"
            case .games:
                return "/games"
            case .createGame:
                return "/games"
            case .joinGame(let gameId):
                return "/games/\(gameId)/join"
            case .gameDetails(let gameId):
                return "/games/\(gameId)"
            case .makeMove(let gameId):
                return "/games/\(gameId)/move"
            }
        }

        var url: URL {
            return URL(string: APIConfiguration.shared.baseURL + path)!
        }
    }

    // MARK: - HTTP Methods
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }

    // MARK: - Headers
    var defaultHeaders: [String: String] {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

    func authorizedHeaders(token: String) -> [String: String] {
        var headers = defaultHeaders
        headers["Authorization"] = "Bearer \(token)"
        return headers
    }
}