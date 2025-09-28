import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let keychain = KeychainManager.shared
    private let networkService = NetworkService.shared

    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let userKey = "current_user"

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadStoredAuth()
    }

    // MARK: - Public Properties
    var accessToken: String? {
        return keychain.loadString(for: accessTokenKey)
    }

    private var refreshToken: String? {
        return keychain.loadString(for: refreshTokenKey)
    }

    // MARK: - Authentication Methods
    func login(email: String, password: String) -> AnyPublisher<Void, NetworkError> {
        let request = LoginRequest(email: email, password: password)

        return networkService.post<AuthResponse, LoginRequest>(
            endpoint: .login,
            body: request,
            requiresAuth: false
        )
        .map { [weak self] response in
            self?.handleAuthSuccess(response)
        }
        .eraseToAnyPublisher()
    }

    func register(email: String, username: String, password: String) -> AnyPublisher<Void, NetworkError> {
        let request = RegisterRequest(email: email, username: username, password: password)

        return networkService.post<AuthResponse, RegisterRequest>(
            endpoint: .register,
            body: request,
            requiresAuth: false
        )
        .map { [weak self] response in
            self?.handleAuthSuccess(response)
        }
        .eraseToAnyPublisher()
    }

    func refreshAccessToken() -> AnyPublisher<Void, NetworkError> {
        guard let refreshToken = refreshToken else {
            return Fail(error: NetworkError.unauthorized)
                .eraseToAnyPublisher()
        }

        let request = RefreshTokenRequest(refreshToken: refreshToken)

        return networkService.post<TokenPair, RefreshTokenRequest>(
            endpoint: .refreshToken,
            body: request,
            requiresAuth: false
        )
        .map { [weak self] tokens in
            self?.storeTokens(tokens)
        }
        .eraseToAnyPublisher()
    }

    func logout() {
        // Clear stored credentials
        keychain.delete(accessTokenKey)
        keychain.delete(refreshTokenKey)
        keychain.delete(userKey)

        // Reset state
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
        }

        // Disconnect WebSocket
        WebSocketService.shared.disconnect()
    }

    func loadProfile() -> AnyPublisher<Void, NetworkError> {
        return networkService.get<ProfileResponse>(endpoint: .profile)
            .map { [weak self] response in
                DispatchQueue.main.async {
                    self?.currentUser = response.user
                    self?.storeUser(response.user)
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods
    private func loadStoredAuth() {
        // Load stored user
        if let user = keychain.loadCodable(User.self, for: userKey) {
            currentUser = user
        }

        // Check if we have valid tokens
        if accessToken != nil {
            isAuthenticated = true

            // Try to refresh profile in background
            loadProfile()
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { }
                )
                .store(in: &cancellables)
        }
    }

    private func handleAuthSuccess(_ response: AuthResponse) {
        storeTokens(response.tokens)
        storeUser(response.user)

        DispatchQueue.main.async {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
    }

    private func storeTokens(_ tokens: TokenPair) {
        keychain.saveString(tokens.accessToken, for: accessTokenKey)
        keychain.saveString(tokens.refreshToken, for: refreshTokenKey)
    }

    private func storeUser(_ user: User) {
        keychain.saveCodable(user, for: userKey)
    }

    // MARK: - Token Validation
    func isTokenExpired() -> Bool {
        guard let token = accessToken else { return true }

        // Basic JWT parsing to check expiration
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3,
              let payloadData = Data(base64Encoded: addPadding(parts[1])),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            return true
        }

        let expirationDate = Date(timeIntervalSince1970: exp)
        return Date() >= expirationDate
    }

    private func addPadding(_ base64String: String) -> String {
        let remainder = base64String.count % 4
        if remainder > 0 {
            return base64String + String(repeating: "=", count: 4 - remainder)
        }
        return base64String
    }

    // MARK: - Auto Token Refresh
    func ensureValidToken() -> AnyPublisher<Void, NetworkError> {
        if isTokenExpired() {
            return refreshAccessToken()
        } else {
            return Just(())
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }
    }
}