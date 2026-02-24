// KeychainManager.swift
// Ingenes
//
// Secure storage using iOS Keychain

import Foundation
import Security

enum KeychainKey: String, CaseIterable {
    case authToken = "com.ingenes.authToken"
    case fileMakerToken = "com.ingenes.fileMakerToken"
    case fileMakerTokenExpiry = "com.ingenes.fileMakerTokenExpiry"
    case savedUsername = "com.ingenes.savedUsername"
    case userRefreshToken = "com.ingenes.refreshToken"

    // MARK: - Cognito Keys
    case cognitoIdToken = "com.ingenes.cognitoIdToken"
    case cognitoAccessToken = "com.ingenes.cognitoAccessToken"
    case cognitoRefreshToken = "com.ingenes.cognitoRefreshToken"
    case cognitoTokenExpiry = "com.ingenes.cognitoTokenExpiry"
}

final class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    // MARK: - Store

    func store(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }

        // Delete existing item first
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToStore
        }
    }

    // MARK: - Retrieve

    func get(_ key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    // MARK: - Delete

    @discardableResult
    func delete(_ key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Clear All

    func clearAll() {
        KeychainKey.allCases.forEach { delete($0) }
    }

    // MARK: - Token Expiry Helpers

    func storeTokenExpiry(_ date: Date, for key: KeychainKey) throws {
        let timestamp = String(date.timeIntervalSince1970)
        try store(timestamp, for: key)
    }

    func getTokenExpiry(_ key: KeychainKey) -> Date? {
        guard let timestampString = get(key),
              let timestamp = Double(timestampString) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case unableToStore
    case unableToRetrieve
    case unableToDelete
    case unexpectedData

    var errorDescription: String? {
        switch self {
        case .unableToStore:
            return "Unable to store item in Keychain"
        case .unableToRetrieve:
            return "Unable to retrieve item from Keychain"
        case .unableToDelete:
            return "Unable to delete item from Keychain"
        case .unexpectedData:
            return "Unexpected data format"
        }
    }
}
