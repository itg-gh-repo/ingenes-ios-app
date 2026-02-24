// FileMakerService.swift
// Ingenes
//
// Actor-based FileMaker API service with token management
// Credentials are fetched securely from AWS Secrets Manager

import Foundation

actor FileMakerService {
    static let shared = FileMakerService()

    private var authToken: String?
    private var tokenExpiry: Date?
    private var cachedCredentials: FileMakerCredentials?

    private init() {}

    // MARK: - Get Credentials

    private func getCredentials() async throws -> FileMakerCredentials {
        if let cached = cachedCredentials {
            return cached
        }

        let credentials = try await SecretsManagerService.shared.getFileMakerCredentials()
        cachedCredentials = credentials
        return credentials
    }

    // MARK: - Token Management

    func getToken() async throws -> String {
        // Check cached token
        if let token = authToken, let expiry = tokenExpiry, expiry > Date() {
            logInfo("Using cached FileMaker token (expires: \(expiry))")
            return token
        }

        // Check Keychain for existing token
        if let storedToken = KeychainManager.shared.get(.fileMakerToken),
           let storedExpiry = KeychainManager.shared.getTokenExpiry(.fileMakerTokenExpiry),
           storedExpiry > Date() {
            logInfo("Using Keychain FileMaker token (expires: \(storedExpiry))")
            self.authToken = storedToken
            self.tokenExpiry = storedExpiry
            return storedToken
        }

        logInfo("No valid token found, requesting new FileMaker session...")

        // Clear any expired tokens from Keychain
        KeychainManager.shared.delete(.fileMakerToken)
        KeychainManager.shared.delete(.fileMakerTokenExpiry)

        // Get credentials from Secrets Manager
        let credentials = try await getCredentials()

        logInfo("FileMaker credentials loaded - baseUrl: \(credentials.baseUrl), username: \(credentials.username)")

        // Request new token
        guard let url = URL(string: "\(credentials.baseUrl)/sessions") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(credentials.base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)

        logInfo("FileMaker session URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        logInfo("FileMaker session response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            logError("FileMaker session failed with status \(httpResponse.statusCode): \(responseBody)")
            // Clear all cached credentials since they might be invalid
            cachedCredentials = nil
            await SecretsManagerService.shared.clearCache()
            throw FileMakerError.authenticationFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        let newToken = tokenResponse.response.token
        let newExpiry = Date().addingTimeInterval(600) // 10 minutes

        // Cache token
        self.authToken = newToken
        self.tokenExpiry = newExpiry

        // Store in Keychain
        try? KeychainManager.shared.store(newToken, for: .fileMakerToken)
        try? KeychainManager.shared.storeTokenExpiry(newExpiry, for: .fileMakerTokenExpiry)

        return newToken
    }

    func clearToken() {
        authToken = nil
        tokenExpiry = nil
        cachedCredentials = nil
        KeychainManager.shared.delete(.fileMakerToken)
        KeychainManager.shared.delete(.fileMakerTokenExpiry)
    }

    // MARK: - Get Base URL

    private func getBaseUrl() async throws -> String {
        let credentials = try await getCredentials()
        return credentials.baseUrl
    }

    // MARK: - User Validation

    /// Validates a user in FileMaker database after Cognito authentication
    /// - Parameters:
    ///   - email: User's email address
    ///   - companyId: Company ID to validate against
    /// - Returns: User data from FileMaker if found
    func validateUser(email: String, companyId: String) async throws -> User {
        logInfo("FileMaker validateUser called - email: \(email), companyId: \(companyId)")

        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        guard let url = URL(string: "\(baseUrl)/layouts/@Usuarios/_find") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Query to find user by email
        // FileMaker exact match syntax: ==value (no quotes around value)
        let queryParams: [String: String] = [
            "Usu_Mail": "==\(email)"
        ]

        let findRequest = FileMakerFindRequest(query: queryParams)

        request.httpBody = try JSONEncoder().encode(findRequest)

        logInfo("FileMaker URL: \(url.absoluteString)")
        logInfo("FileMaker request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        logInfo("FileMaker response status: \(httpResponse.statusCode)")
        let responseBody = String(data: data, encoding: .utf8) ?? ""
        logInfo("FileMaker response body: \(responseBody)")

        if httpResponse.statusCode == 401 {
            clearToken()
            throw APIError.unauthorized
        }

        // FileMaker returns 400 with error code 401 when no records found via _find
        // Also can return 500 for other errors
        if httpResponse.statusCode != 200 {
            // Try to parse FileMaker error
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let messages = json["messages"] as? [[String: Any]],
               let firstMessage = messages.first,
               let code = firstMessage["code"] as? String {
                logError("FileMaker error code: \(code), message: \(firstMessage["message"] ?? "")")
                // Code 401 = No records match the request
                if code == "401" {
                    throw FileMakerError.recordNotFound
                }
            }
            logError("FileMaker user validation failed with status: \(httpResponse.statusCode)")
            throw FileMakerError.recordNotFound
        }

        do {
            let recordsResponse = try JSONDecoder().decode(
                FileMakerRecordsResponse<FileMakerUserFieldData>.self,
                from: data
            )

            guard let firstRecord = recordsResponse.response.data.first else {
                logError("FileMaker: No records in response data array")
                throw FileMakerError.recordNotFound
            }

            let user = firstRecord.fieldData.toUser(recordId: firstRecord.recordId)

            logInfo("User validated in FileMaker: \(user.fullName), type: \(user.userType), email: \(user.email)")

            return user
        } catch let decodingError as DecodingError {
            logError("FileMaker JSON decoding error: \(decodingError)")
            logError("Raw response for debugging: \(responseBody)")
            throw FileMakerError.invalidResponse("Error al procesar respuesta del servidor")
        } catch {
            logError("FileMaker unexpected error: \(error)")
            throw error
        }
    }

    func passwordRecovery(email: String) async throws -> Bool {
        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        guard let url = URL(string: "\(baseUrl)/layouts/_webappSalesContacts/script/webapp_sendPassword") else {
            throw APIError.invalidURL
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "script.param", value: email)
        ]

        guard let requestURL = components.url else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        return (200...299).contains(httpResponse.statusCode)
    }

    // MARK: - Update Login Time

    func updateLoginTime(recordId: String) async throws {
        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        guard let url = URL(string: "\(baseUrl)/layouts/_webappSalesContacts/records/\(recordId)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let formatter = ISO8601DateFormatter()
        let payload: [String: Any] = [
            "fieldData": [
                "LastLoginTime": formatter.string(from: Date())
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Don't throw - this is a non-critical update
            logWarning("Failed to update login time")
            return
        }
    }
}
