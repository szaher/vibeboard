import Foundation

struct Environment {
    static let shared = Environment()

    private init() {}

    // MARK: - Configuration
    private let configuration: [String: Any] = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return [:]
        }
        return plist
    }()

    // MARK: - API Configuration
    var baseURL: String {
        return configuration["BASE_URL"] as? String ?? "http://localhost:8181/api/v1"
    }

    var websocketURL: String {
        return configuration["WEBSOCKET_URL"] as? String ?? "ws://localhost:8181/api/v1/ws"
    }

    var environment: String {
        return configuration["ENVIRONMENT"] as? String ?? "development"
    }

    var isProduction: Bool {
        return environment == "production"
    }

    var isDevelopment: Bool {
        return environment == "development"
    }

    // MARK: - Debug Configuration
    var enableLogging: Bool {
        return configuration["ENABLE_LOGGING"] as? Bool ?? !isProduction
    }

    var enableDebugMenu: Bool {
        return configuration["ENABLE_DEBUG_MENU"] as? Bool ?? isDevelopment
    }
}