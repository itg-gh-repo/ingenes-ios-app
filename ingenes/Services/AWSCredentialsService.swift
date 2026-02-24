// AWSCredentialsService.swift
// Ingenes
//
// AWS Credentials Service for obtaining temporary AWS credentials
// Uses Cognito Identity Pool to exchange Cognito tokens for AWS credentials

import Foundation

// MARK: - AWS Credentials

struct AWSCredentials {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String
    let expiration: Date

    var isExpired: Bool {
        expiration < Date()
    }

    var isExpiringSoon: Bool {
        expiration < Date().addingTimeInterval(300) // 5 minutes
    }
}

// MARK: - AWS Credentials Error

enum AWSCredentialsError: LocalizedError {
    case notAuthenticated
    case identityError(String)
    case credentialsError(String)
    case networkError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Usuario no autenticado"
        case .identityError(let message):
            return "Error de identidad: \(message)"
        case .credentialsError(let message):
            return "Error de credenciales: \(message)"
        case .networkError:
            return "Error de conexión"
        }
    }
}

// MARK: - AWS Credentials Service

actor AWSCredentialsService {
    static let shared = AWSCredentialsService()

    private var cachedCredentials: AWSCredentials?
    private var cachedIdentityId: String?

    private let identityPoolId = "us-east-1:c9967d40-795e-4682-a4f4-67ab4286c7dd"
    private let region = "us-east-1"

    private init() {}

    // MARK: - Get AWS Credentials

    func getCredentials() async throws -> AWSCredentials {
        // Return cached credentials if still valid
        if let cached = cachedCredentials, !cached.isExpiringSoon {
            return cached
        }

        // Get Cognito ID token
        guard let idToken = KeychainManager.shared.get(.cognitoIdToken) else {
            throw AWSCredentialsError.notAuthenticated
        }

        // Step 1: Get Identity ID
        let identityId = try await getIdentityId(idToken: idToken)

        // Step 2: Get AWS credentials
        let credentials = try await getCredentialsForIdentity(identityId: identityId, idToken: idToken)

        // Cache credentials
        cachedCredentials = credentials
        cachedIdentityId = identityId

        return credentials
    }

    // MARK: - Clear Cached Credentials

    func clearCredentials() {
        cachedCredentials = nil
        cachedIdentityId = nil
    }

    // MARK: - Get Identity ID

    private func getIdentityId(idToken: String) async throws -> String {
        // If we have a cached identity ID and valid credentials, reuse it
        if let identityId = cachedIdentityId, cachedCredentials?.isExpired == false {
            return identityId
        }

        let endpoint = URL(string: "https://cognito-identity.\(region).amazonaws.com/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue("AWSCognitoIdentityService.GetId", forHTTPHeaderField: "X-Amz-Target")

        let providerName = "cognito-idp.\(region).amazonaws.com/\(AppConfig.cognitoUserPoolId)"

        let body: [String: Any] = [
            "IdentityPoolId": identityPoolId,
            "Logins": [
                providerName: idToken
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AWSCredentialsError.networkError
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            if httpResponse.statusCode != 200 {
                let message = json["message"] as? String ?? "Unknown error"
                throw AWSCredentialsError.identityError(message)
            }

            guard let identityId = json["IdentityId"] as? String else {
                throw AWSCredentialsError.identityError("No identity ID returned")
            }

            return identityId

        } catch let error as AWSCredentialsError {
            throw error
        } catch {
            throw AWSCredentialsError.networkError
        }
    }

    // MARK: - Get Credentials for Identity

    private func getCredentialsForIdentity(identityId: String, idToken: String) async throws -> AWSCredentials {
        let endpoint = URL(string: "https://cognito-identity.\(region).amazonaws.com/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue("AWSCognitoIdentityService.GetCredentialsForIdentity", forHTTPHeaderField: "X-Amz-Target")

        let providerName = "cognito-idp.\(region).amazonaws.com/\(AppConfig.cognitoUserPoolId)"

        let body: [String: Any] = [
            "IdentityId": identityId,
            "Logins": [
                providerName: idToken
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AWSCredentialsError.networkError
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            if httpResponse.statusCode != 200 {
                let message = json["message"] as? String ?? "Unknown error"
                throw AWSCredentialsError.credentialsError(message)
            }

            guard let credentialsJson = json["Credentials"] as? [String: Any],
                  let accessKeyId = credentialsJson["AccessKeyId"] as? String,
                  let secretAccessKey = credentialsJson["SecretKey"] as? String,
                  let sessionToken = credentialsJson["SessionToken"] as? String,
                  let expirationTimestamp = credentialsJson["Expiration"] as? Double else {
                throw AWSCredentialsError.credentialsError("Invalid credentials response")
            }

            let expiration = Date(timeIntervalSince1970: expirationTimestamp)

            return AWSCredentials(
                accessKeyId: accessKeyId,
                secretAccessKey: secretAccessKey,
                sessionToken: sessionToken,
                expiration: expiration
            )

        } catch let error as AWSCredentialsError {
            throw error
        } catch {
            throw AWSCredentialsError.networkError
        }
    }
}
