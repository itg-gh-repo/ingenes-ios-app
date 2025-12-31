// AppConfig.swift
// TAG2
//
// Configuration constants for the app

import Foundation

enum AppConfig {
    // MARK: - App Info
    static let appVersion = "1.0.0"
    static let bundleId = "com.tag2.app"
    static let appName = "TAG2"

    // MARK: - AWS Cognito Configuration
    // Values are loaded from Info.plist
    static var cognitoRegion: String {
        Bundle.main.infoDictionary?["COGNITO_REGION"] as? String ?? "us-east-1"
    }

    static var cognitoUserPoolId: String {
        Bundle.main.infoDictionary?["COGNITO_USER_POOL_ID"] as? String ?? ""
    }

    static var cognitoClientId: String {
        Bundle.main.infoDictionary?["COGNITO_CLIENT_ID"] as? String ?? ""
    }

    static var cognitoClientSecret: String {
        Bundle.main.infoDictionary?["COGNITO_CLIENT_SECRET"] as? String ?? ""
    }

    // MARK: - AWS Cognito Identity Pool
    // Used for obtaining AWS credentials to access Secrets Manager
    static let cognitoIdentityPoolId = "us-east-1:c9967d40-795e-4682-a4f4-67ab4286c7dd"

    // MARK: - AWS Secrets Manager
    // Secret name for FileMaker credentials
    static let fileMakerSecretName = "TAG2/FileMaker/Credentials"

    // MARK: - Token Cache Duration
    static let tokenCacheDuration: TimeInterval = 600 // 10 minutes
    static let cognitoTokenDuration: TimeInterval = 3600 // 1 hour (Cognito default)
    static let secretsCacheDuration: TimeInterval = 3600 // 1 hour

    // MARK: - API Timeouts
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60

    // MARK: - Splash Screen Duration
    static let splashDuration: TimeInterval = 2.4
}
