// CognitoService.swift
// TAG2
//
// AWS Cognito authentication service
// NOTE: Add AWS SDK via Swift Package Manager to enable full Cognito integration
// URL: https://github.com/awslabs/aws-sdk-swift
// Packages needed: AWSCognitoIdentityProvider

import Foundation
import CommonCrypto

// MARK: - Cognito Errors

enum CognitoError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case userNotConfirmed
    case passwordResetRequired
    case newPasswordRequired
    case invalidPassword
    case codeMismatch
    case expiredCode
    case limitExceeded
    case networkError
    case configurationError
    case sdkNotConfigured
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Credenciales inválidas. Por favor verifica tu correo y contraseña."
        case .userNotFound:
            return "Usuario no encontrado. Contacta al administrador."
        case .userNotConfirmed:
            return "Tu cuenta no ha sido confirmada. Contacta al administrador."
        case .passwordResetRequired:
            return "Debes restablecer tu contraseña antes de continuar."
        case .newPasswordRequired:
            return "Debes establecer una nueva contraseña."
        case .invalidPassword:
            return "La contraseña no cumple con los requisitos de seguridad."
        case .codeMismatch:
            return "El código de verificación es incorrecto."
        case .expiredCode:
            return "El código de verificación ha expirado. Solicita uno nuevo."
        case .limitExceeded:
            return "Has excedido el límite de intentos. Intenta más tarde."
        case .networkError:
            return "Error de conexión. Verifica tu conexión a internet."
        case .configurationError:
            return "Error de configuración. Contacta al soporte técnico."
        case .sdkNotConfigured:
            return "AWS SDK no configurado. Contacta al soporte técnico."
        case .unknown(let message):
            return "Error: \(message)"
        }
    }
}

// MARK: - Cognito User Attributes

struct CognitoUserAttributes {
    let email: String
    let firstName: String
    let lastName: String
    let storeName: String
    let customerId: String
    let locationStatus: String
    let recordId: String
}

// MARK: - Cognito Service

actor CognitoService {
    static let shared = CognitoService()

    private init() {}

    // MARK: - SECRET_HASH Calculation

    private func calculateSecretHash(username: String) -> String? {
        let clientSecret = AppConfig.cognitoClientSecret
        let clientId = AppConfig.cognitoClientId

        guard !clientSecret.isEmpty else { return nil }

        let message = username + clientId
        guard let messageData = message.data(using: .utf8),
              let keyData = clientSecret.data(using: .utf8) else {
            return nil
        }

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            messageData.withUnsafeBytes { messageBytes in
                CCHmac(
                    CCHmacAlgorithm(kCCHmacAlgSHA256),
                    keyBytes.baseAddress,
                    keyData.count,
                    messageBytes.baseAddress,
                    messageData.count,
                    &digest
                )
            }
        }

        return Data(digest).base64EncodedString()
    }

    // MARK: - Sign In

    func signIn(username: String, password: String) async throws -> CognitoUserAttributes {
        // Check if Cognito is configured
        guard !AppConfig.cognitoUserPoolId.isEmpty,
              !AppConfig.cognitoClientId.isEmpty else {
            throw CognitoError.configurationError
        }

        // Build the request
        let secretHash = calculateSecretHash(username: username)

        // Cognito InitiateAuth API endpoint
        let region = AppConfig.cognitoRegion
        let endpoint = URL(string: "https://cognito-idp.\(region).amazonaws.com/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue("AWSCognitoIdentityProviderService.InitiateAuth", forHTTPHeaderField: "X-Amz-Target")

        var authParameters: [String: String] = [
            "USERNAME": username,
            "PASSWORD": password
        ]

        if let secretHash = secretHash {
            authParameters["SECRET_HASH"] = secretHash
        }

        let body: [String: Any] = [
            "AuthFlow": "USER_PASSWORD_AUTH",
            "ClientId": AppConfig.cognitoClientId,
            "AuthParameters": authParameters
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CognitoError.networkError
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            // Check for errors
            if httpResponse.statusCode != 200 {
                let errorType = json["__type"] as? String ?? ""

                if errorType.contains("NotAuthorizedException") {
                    throw CognitoError.invalidCredentials
                } else if errorType.contains("UserNotFoundException") {
                    throw CognitoError.userNotFound
                } else if errorType.contains("UserNotConfirmedException") {
                    throw CognitoError.userNotConfirmed
                } else if errorType.contains("PasswordResetRequiredException") {
                    throw CognitoError.passwordResetRequired
                } else if errorType.contains("TooManyRequestsException") {
                    throw CognitoError.limitExceeded
                } else {
                    let message = json["message"] as? String ?? "Error desconocido"
                    throw CognitoError.unknown(message)
                }
            }

            // Check for challenges
            if let challengeName = json["ChallengeName"] as? String {
                if challengeName == "NEW_PASSWORD_REQUIRED" {
                    throw CognitoError.newPasswordRequired
                } else {
                    throw CognitoError.unknown("Challenge no soportado: \(challengeName)")
                }
            }

            // Get tokens from response
            guard let authResult = json["AuthenticationResult"] as? [String: Any],
                  let idToken = authResult["IdToken"] as? String,
                  let accessToken = authResult["AccessToken"] as? String,
                  let refreshToken = authResult["RefreshToken"] as? String else {
                throw CognitoError.unknown("No se recibieron tokens de autenticación")
            }

            let expiresIn = authResult["ExpiresIn"] as? Int ?? 3600

            // Store tokens in Keychain
            try storeTokens(
                idToken: idToken,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            )

            // Parse user attributes from ID token
            let attributes = try parseIdToken(idToken)

            return attributes

        } catch let error as CognitoError {
            throw error
        } catch {
            throw CognitoError.networkError
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        // Clear tokens from Keychain first
        let accessToken = KeychainManager.shared.get(.cognitoAccessToken)

        KeychainManager.shared.delete(.cognitoIdToken)
        KeychainManager.shared.delete(.cognitoAccessToken)
        KeychainManager.shared.delete(.cognitoRefreshToken)
        KeychainManager.shared.delete(.cognitoTokenExpiry)

        // Optionally call global sign out to invalidate all sessions
        if let accessToken = accessToken {
            let region = AppConfig.cognitoRegion
            let endpoint = URL(string: "https://cognito-idp.\(region).amazonaws.com/")!

            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
            request.setValue("AWSCognitoIdentityProviderService.GlobalSignOut", forHTTPHeaderField: "X-Amz-Target")

            let body: [String: Any] = [
                "AccessToken": accessToken
            ]

            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            // Fire and forget - we don't care about the response
            _ = try? await URLSession.shared.data(for: request)
        }
    }

    // MARK: - Forgot Password

    func forgotPassword(username: String) async throws {
        guard !AppConfig.cognitoClientId.isEmpty else {
            throw CognitoError.configurationError
        }

        let region = AppConfig.cognitoRegion
        let endpoint = URL(string: "https://cognito-idp.\(region).amazonaws.com/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue("AWSCognitoIdentityProviderService.ForgotPassword", forHTTPHeaderField: "X-Amz-Target")

        var body: [String: Any] = [
            "ClientId": AppConfig.cognitoClientId,
            "Username": username
        ]

        if let secretHash = calculateSecretHash(username: username) {
            body["SecretHash"] = secretHash
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CognitoError.networkError
            }

            if httpResponse.statusCode != 200 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                let errorType = json["__type"] as? String ?? ""

                if errorType.contains("UserNotFoundException") {
                    throw CognitoError.userNotFound
                } else if errorType.contains("LimitExceededException") {
                    throw CognitoError.limitExceeded
                } else {
                    let message = json["message"] as? String ?? "Error al enviar código"
                    throw CognitoError.unknown(message)
                }
            }
        } catch let error as CognitoError {
            throw error
        } catch {
            throw CognitoError.networkError
        }
    }

    // MARK: - Confirm Forgot Password

    func confirmForgotPassword(username: String, code: String, newPassword: String) async throws {
        guard !AppConfig.cognitoClientId.isEmpty else {
            throw CognitoError.configurationError
        }

        let region = AppConfig.cognitoRegion
        let endpoint = URL(string: "https://cognito-idp.\(region).amazonaws.com/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue("AWSCognitoIdentityProviderService.ConfirmForgotPassword", forHTTPHeaderField: "X-Amz-Target")

        var body: [String: Any] = [
            "ClientId": AppConfig.cognitoClientId,
            "Username": username,
            "ConfirmationCode": code,
            "Password": newPassword
        ]

        if let secretHash = calculateSecretHash(username: username) {
            body["SecretHash"] = secretHash
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CognitoError.networkError
            }

            if httpResponse.statusCode != 200 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                let errorType = json["__type"] as? String ?? ""

                if errorType.contains("CodeMismatchException") {
                    throw CognitoError.codeMismatch
                } else if errorType.contains("ExpiredCodeException") {
                    throw CognitoError.expiredCode
                } else if errorType.contains("InvalidPasswordException") {
                    throw CognitoError.invalidPassword
                } else {
                    let message = json["message"] as? String ?? "Error al cambiar contraseña"
                    throw CognitoError.unknown(message)
                }
            }
        } catch let error as CognitoError {
            throw error
        } catch {
            throw CognitoError.networkError
        }
    }

    // MARK: - Refresh Tokens

    func refreshTokens() async throws -> Bool {
        guard let refreshToken = KeychainManager.shared.get(.cognitoRefreshToken),
              let username = KeychainManager.shared.get(.savedUsername) else {
            return false
        }

        guard !AppConfig.cognitoClientId.isEmpty else {
            return false
        }

        let region = AppConfig.cognitoRegion
        let endpoint = URL(string: "https://cognito-idp.\(region).amazonaws.com/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue("AWSCognitoIdentityProviderService.InitiateAuth", forHTTPHeaderField: "X-Amz-Target")

        var authParameters: [String: String] = [
            "REFRESH_TOKEN": refreshToken
        ]

        if let secretHash = calculateSecretHash(username: username) {
            authParameters["SECRET_HASH"] = secretHash
        }

        let body: [String: Any] = [
            "AuthFlow": "REFRESH_TOKEN_AUTH",
            "ClientId": AppConfig.cognitoClientId,
            "AuthParameters": authParameters
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            guard let authResult = json["AuthenticationResult"] as? [String: Any],
                  let idToken = authResult["IdToken"] as? String,
                  let accessToken = authResult["AccessToken"] as? String else {
                return false
            }

            let expiresIn = authResult["ExpiresIn"] as? Int ?? 3600
            let newRefreshToken = authResult["RefreshToken"] as? String ?? refreshToken

            try storeTokens(
                idToken: idToken,
                accessToken: accessToken,
                refreshToken: newRefreshToken,
                expiresIn: expiresIn
            )

            return true
        } catch {
            return false
        }
    }

    // MARK: - Check Authentication

    func isAuthenticated() -> Bool {
        guard let _ = KeychainManager.shared.get(.cognitoAccessToken),
              let expiry = KeychainManager.shared.getTokenExpiry(.cognitoTokenExpiry) else {
            return false
        }
        return expiry > Date()
    }

    func getAccessToken() -> String? {
        return KeychainManager.shared.get(.cognitoAccessToken)
    }

    // MARK: - Private Helpers

    private func storeTokens(idToken: String, accessToken: String, refreshToken: String, expiresIn: Int) throws {
        try KeychainManager.shared.store(idToken, for: .cognitoIdToken)
        try KeychainManager.shared.store(accessToken, for: .cognitoAccessToken)
        try KeychainManager.shared.store(refreshToken, for: .cognitoRefreshToken)

        let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        try KeychainManager.shared.storeTokenExpiry(expiryDate, for: .cognitoTokenExpiry)
    }

    private func parseIdToken(_ idToken: String) throws -> CognitoUserAttributes {
        // JWT tokens have 3 parts separated by dots
        let parts = idToken.split(separator: ".")
        guard parts.count == 3 else {
            throw CognitoError.unknown("Token ID inválido")
        }

        // Decode the payload (second part)
        var payload = String(parts[1])

        // Add padding if needed for base64 decoding
        while payload.count % 4 != 0 {
            payload += "="
        }

        // Handle URL-safe base64
        let base64 = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        guard let payloadData = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw CognitoError.unknown("No se pudo decodificar el token")
        }

        // Extract attributes from token claims
        let email = json["email"] as? String ?? ""
        let firstName = json["custom:firstName"] as? String ?? json["given_name"] as? String ?? ""
        let lastName = json["custom:lastName"] as? String ?? json["family_name"] as? String ?? ""
        let storeName = json["custom:storeName"] as? String ?? ""
        let customerId = json["custom:customerId"] as? String ?? ""
        let locationStatus = json["custom:locationStatus"] as? String ?? "Active"
        let recordId = json["custom:recordId"] as? String ?? json["sub"] as? String ?? ""

        return CognitoUserAttributes(
            email: email,
            firstName: firstName,
            lastName: lastName,
            storeName: storeName,
            customerId: customerId,
            locationStatus: locationStatus,
            recordId: recordId
        )
    }
}
