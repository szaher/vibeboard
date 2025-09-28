import Foundation
import Combine

class NetworkService {
    static let shared = NetworkService()

    private let session: URLSession
    private let config = APIConfiguration.shared

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Generic Request Method
    func request<T: Codable>(
        endpoint: APIConfiguration.Endpoint,
        method: APIConfiguration.HTTPMethod = .GET,
        body: Data? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, NetworkError> {

        var request = URLRequest(url: endpoint.url)
        request.httpMethod = method.rawValue

        // Set headers
        if requiresAuth {
            guard let token = AuthManager.shared.accessToken else {
                return Fail(error: NetworkError.unauthorized)
                    .eraseToAnyPublisher()
            }
            config.authorizedHeaders(token: token).forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        } else {
            config.defaultHeaders.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Set body
        if let body = body {
            request.httpBody = body
        }

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw NetworkError.unauthorized
                case 400...499:
                    throw NetworkError.clientError(httpResponse.statusCode)
                case 500...599:
                    throw NetworkError.serverError(httpResponse.statusCode)
                default:
                    throw NetworkError.unknown
                }
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if error is DecodingError {
                    return NetworkError.decodingError
                } else {
                    return NetworkError.unknown
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Convenience Methods
    func get<T: Codable>(
        endpoint: APIConfiguration.Endpoint,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, NetworkError> {
        return request(endpoint: endpoint, method: .GET, requiresAuth: requiresAuth)
    }

    func post<T: Codable, U: Codable>(
        endpoint: APIConfiguration.Endpoint,
        body: U,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, NetworkError> {
        do {
            let data = try JSONEncoder().encode(body)
            return request(endpoint: endpoint, method: .POST, body: data, requiresAuth: requiresAuth)
        } catch {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
    }

    func post<T: Codable>(
        endpoint: APIConfiguration.Endpoint,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, NetworkError> {
        return request(endpoint: endpoint, method: .POST, requiresAuth: requiresAuth)
    }
}

// MARK: - Network Error
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case encodingError
    case invalidResponse
    case unauthorized
    case clientError(Int)
    case serverError(Int)
    case unknown

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response"
        case .unauthorized:
            return "Unauthorized"
        case .clientError(let code):
            return "Client error: \(code)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unknown:
            return "Unknown error"
        }
    }
}