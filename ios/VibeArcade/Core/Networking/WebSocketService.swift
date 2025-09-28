import Foundation
import Combine

class WebSocketService: NSObject, ObservableObject {
    static let shared = WebSocketService()

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?

    @Published var connectionState: WebSocketConnectionState = .disconnected
    @Published var lastError: Error?

    private let messageSubject = PassthroughSubject<WebSocketMessage, Never>()
    var messagePublisher: AnyPublisher<WebSocketMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    private override init() {
        super.init()
        setupURLSession()
    }

    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    // MARK: - Connection Management
    func connect() {
        guard connectionState != .connected && connectionState != .connecting else {
            return
        }

        guard let token = AuthManager.shared.accessToken else {
            lastError = WebSocketError.noAuthToken
            return
        }

        connectionState = .connecting

        var request = URLRequest(url: URL(string: APIConfiguration.shared.websocketURL)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()

        startListening()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
    }

    // MARK: - Message Handling
    private func startListening() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleReceivedMessage(message)
                self?.startListening() // Continue listening
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }

    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let webSocketMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                DispatchQueue.main.async {
                    self.messageSubject.send(webSocketMessage)
                }
            }
        case .data(let data):
            if let webSocketMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                DispatchQueue.main.async {
                    self.messageSubject.send(webSocketMessage)
                }
            }
        @unknown default:
            break
        }
    }

    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.lastError = error
            self.connectionState = .disconnected
        }
    }

    // MARK: - Send Messages
    func send(message: WebSocketMessage) {
        guard connectionState == .connected else {
            lastError = WebSocketError.notConnected
            return
        }

        do {
            let data = try JSONEncoder().encode(message)
            let string = String(data: data, encoding: .utf8)!
            let message = URLSessionWebSocketTask.Message.string(string)

            webSocketTask?.send(message) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.lastError = error
                    }
                }
            }
        } catch {
            lastError = error
        }
    }

    // MARK: - Convenience Methods
    func joinRoom(_ roomId: String) {
        let message = WebSocketMessage(
            type: .joinRoom,
            roomId: roomId,
            playerId: AuthManager.shared.currentUser?.id ?? UUID(),
            data: nil,
            timestamp: Date()
        )
        send(message: message)
    }

    func leaveRoom(_ roomId: String) {
        let message = WebSocketMessage(
            type: .leaveRoom,
            roomId: roomId,
            playerId: AuthManager.shared.currentUser?.id ?? UUID(),
            data: nil,
            timestamp: Date()
        )
        send(message: message)
    }

    func sendGameMove(roomId: String, moveData: Data) {
        let message = WebSocketMessage(
            type: .gameMove,
            roomId: roomId,
            playerId: AuthManager.shared.currentUser?.id ?? UUID(),
            data: moveData,
            timestamp: Date()
        )
        send(message: message)
    }

    func sendChatMessage(roomId: String, text: String) {
        let chatData = ChatData(message: text)
        if let data = try? JSONEncoder().encode(chatData) {
            let message = WebSocketMessage(
                type: .chatMessage,
                roomId: roomId,
                playerId: AuthManager.shared.currentUser?.id ?? UUID(),
                data: data,
                timestamp: Date()
            )
            send(message: message)
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.connectionState = .connected
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
}

// MARK: - Supporting Types
enum WebSocketConnectionState {
    case disconnected
    case connecting
    case connected
}

enum WebSocketError: Error {
    case noAuthToken
    case notConnected
    case encodingError
    case decodingError

    var localizedDescription: String {
        switch self {
        case .noAuthToken:
            return "No authentication token available"
        case .notConnected:
            return "WebSocket not connected"
        case .encodingError:
            return "Failed to encode message"
        case .decodingError:
            return "Failed to decode message"
        }
    }
}

struct ChatData: Codable {
    let message: String
}