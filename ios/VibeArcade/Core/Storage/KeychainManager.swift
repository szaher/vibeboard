import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    private let serviceName = "com.acmegames.vibearcade"

    // MARK: - Public Methods
    func save(_ data: Data, for key: String) -> Bool {
        delete(key) // Remove existing item first

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func load(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            return nil
        }

        return item as? Data
    }

    func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Convenience Methods
    func saveString(_ string: String, for key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, for: key)
    }

    func loadString(for key: String) -> String? {
        guard let data = load(key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveCodable<T: Codable>(_ object: T, for key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            return save(data, for: key)
        } catch {
            return false
        }
    }

    func loadCodable<T: Codable>(_ type: T.Type, for key: String) -> T? {
        guard let data = load(key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return nil
        }
    }
}