// SecretsManagerService.swift
// Ingenes
//
// AWS Secrets Manager Service for fetching FileMaker credentials
// Uses AWS Signature Version 4 for authentication

import Foundation
import CommonCrypto

// MARK: - FileMaker Credentials

struct FileMakerCredentials: Codable {
    let baseUrl: String
    let username: String
    let password: String

    var base64Credentials: String {
        let credentials = "\(username):\(password)"
        return Data(credentials.utf8).base64EncodedString()
    }
}

// MARK: - Secrets Manager Error

enum SecretsManagerError: LocalizedError {
    case noCredentials
    case secretNotFound
    case accessDenied
    case invalidSecret
    case networkError
    case signingError

    var errorDescription: String? {
        switch self {
        case .noCredentials:
            return "No hay credenciales de AWS disponibles"
        case .secretNotFound:
            return "Secreto no encontrado"
        case .accessDenied:
            return "Acceso denegado al secreto"
        case .invalidSecret:
            return "Formato de secreto inválido"
        case .networkError:
            return "Error de conexión"
        case .signingError:
            return "Error de firma de solicitud"
        }
    }
}

// MARK: - Secrets Manager Service

actor SecretsManagerService {
    static let shared = SecretsManagerService()

    private var cachedCredentials: FileMakerCredentials?
    private var cacheExpiry: Date?

    private let secretName = "Ingenes/FileMaker/Credentials"
    private let region = "us-east-1"
    private let service = "secretsmanager"
    private let cacheDuration: TimeInterval = 3600 // 1 hour

    private init() {}

    // MARK: - Get FileMaker Credentials

    func getFileMakerCredentials() async throws -> FileMakerCredentials {
        // Return cached credentials if still valid
        if let cached = cachedCredentials,
           let expiry = cacheExpiry,
           expiry > Date() {
            return cached
        }

        // Get AWS credentials
        let awsCredentials = try await AWSCredentialsService.shared.getCredentials()

        // Fetch secret from Secrets Manager
        let credentials = try await fetchSecret(awsCredentials: awsCredentials)

        // Cache credentials
        cachedCredentials = credentials
        cacheExpiry = Date().addingTimeInterval(cacheDuration)

        return credentials
    }

    // MARK: - Clear Cache

    func clearCache() {
        cachedCredentials = nil
        cacheExpiry = nil
    }

    // MARK: - Fetch Secret

    private func fetchSecret(awsCredentials: AWSCredentials) async throws -> FileMakerCredentials {
        let endpoint = URL(string: "https://secretsmanager.\(region).amazonaws.com/")!
        let now = Date()

        // Create request body
        let bodyJson: [String: Any] = [
            "SecretId": secretName
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: bodyJson)
        let bodyString = String(data: bodyData, encoding: .utf8) ?? ""

        // Create the request
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = bodyData

        // Add headers
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue("secretsmanager.\(region).amazonaws.com", forHTTPHeaderField: "Host")
        request.setValue("secretsmanager.GetSecretValue", forHTTPHeaderField: "X-Amz-Target")
        request.setValue(awsCredentials.sessionToken, forHTTPHeaderField: "X-Amz-Security-Token")

        // Sign the request with AWS Signature Version 4
        let signedRequest = try signRequest(
            request: request,
            body: bodyString,
            credentials: awsCredentials,
            date: now
        )

        do {
            let (data, response) = try await URLSession.shared.data(for: signedRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw SecretsManagerError.networkError
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            if httpResponse.statusCode == 400 {
                let errorType = json["__type"] as? String ?? ""
                if errorType.contains("ResourceNotFoundException") {
                    throw SecretsManagerError.secretNotFound
                } else if errorType.contains("AccessDeniedException") {
                    throw SecretsManagerError.accessDenied
                }
                let message = json["message"] as? String ?? "Unknown error"
                logError("Secrets Manager error: \(message)")
                throw SecretsManagerError.accessDenied
            }

            guard httpResponse.statusCode == 200 else {
                throw SecretsManagerError.networkError
            }

            guard let secretString = json["SecretString"] as? String,
                  let secretData = secretString.data(using: .utf8) else {
                logError("SecretString not found or invalid in response")
                throw SecretsManagerError.invalidSecret
            }

            logDebug("Secret string received, attempting to decode...")

            do {
                let credentials = try JSONDecoder().decode(FileMakerCredentials.self, from: secretData)
                logInfo("FileMaker credentials loaded successfully")
                return credentials
            } catch let decodingError {
                logError("Failed to decode FileMaker credentials: \(decodingError)")
                logError("Secret string content: \(secretString)")
                throw SecretsManagerError.invalidSecret
            }

        } catch let error as SecretsManagerError {
            throw error
        } catch {
            logError("Secrets Manager unexpected error: \(error)")
            throw SecretsManagerError.networkError
        }
    }

    // MARK: - AWS Signature Version 4

    private func signRequest(
        request: URLRequest,
        body: String,
        credentials: AWSCredentials,
        date: Date
    ) throws -> URLRequest {
        var signedRequest = request

        // Date formatters
        let amzDateFormatter = DateFormatter()
        amzDateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        amzDateFormatter.timeZone = TimeZone(identifier: "UTC")

        let dateStampFormatter = DateFormatter()
        dateStampFormatter.dateFormat = "yyyyMMdd"
        dateStampFormatter.timeZone = TimeZone(identifier: "UTC")

        let amzDate = amzDateFormatter.string(from: date)
        let dateStamp = dateStampFormatter.string(from: date)

        signedRequest.setValue(amzDate, forHTTPHeaderField: "X-Amz-Date")

        // Create canonical request
        let method = "POST"
        let canonicalUri = "/"
        let canonicalQueryString = ""

        // Create canonical headers
        let host = "\(service).\(region).amazonaws.com"
        let contentType = "application/x-amz-json-1.1"
        let target = "secretsmanager.GetSecretValue"

        let canonicalHeaders = """
        content-type:\(contentType)
        host:\(host)
        x-amz-date:\(amzDate)
        x-amz-security-token:\(credentials.sessionToken)
        x-amz-target:\(target)
        """

        let signedHeaders = "content-type;host;x-amz-date;x-amz-security-token;x-amz-target"

        // Hash the payload
        let payloadHash = sha256Hash(body)

        let canonicalRequest = """
        \(method)
        \(canonicalUri)
        \(canonicalQueryString)
        \(canonicalHeaders)

        \(signedHeaders)
        \(payloadHash)
        """

        // Create string to sign
        let algorithm = "AWS4-HMAC-SHA256"
        let credentialScope = "\(dateStamp)/\(region)/\(service)/aws4_request"
        let hashedCanonicalRequest = sha256Hash(canonicalRequest)

        let stringToSign = """
        \(algorithm)
        \(amzDate)
        \(credentialScope)
        \(hashedCanonicalRequest)
        """

        // Calculate signature
        let kDate = hmacSHA256(key: "AWS4\(credentials.secretAccessKey)".data(using: .utf8)!, data: dateStamp)
        let kRegion = hmacSHA256(key: kDate, data: region)
        let kService = hmacSHA256(key: kRegion, data: service)
        let kSigning = hmacSHA256(key: kService, data: "aws4_request")
        let signature = hmacSHA256(key: kSigning, data: stringToSign).map { String(format: "%02x", $0) }.joined()

        // Create authorization header
        let authorizationHeader = "\(algorithm) Credential=\(credentials.accessKeyId)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"

        signedRequest.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")

        return signedRequest
    }

    // MARK: - Crypto Helpers

    private func sha256Hash(_ string: String) -> String {
        let data = string.data(using: .utf8)!
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private func hmacSHA256(key: Data, data: String) -> Data {
        let dataBytes = data.data(using: .utf8)!
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        key.withUnsafeBytes { keyBytes in
            dataBytes.withUnsafeBytes { dataBytes in
                CCHmac(
                    CCHmacAlgorithm(kCCHmacAlgSHA256),
                    keyBytes.baseAddress,
                    key.count,
                    dataBytes.baseAddress,
                    dataBytes.count,
                    &hash
                )
            }
        }

        return Data(hash)
    }
}
