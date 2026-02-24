// AppState.swift
// Ingenes
//
// Global app state management

import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var selectedLocation: Location?
    @Published var isDarkMode: Bool

    init() {
        // Load saved preferences
        self.isDarkMode = UserDefaultsManager.shared.isDarkMode

        // Check for existing Cognito auth
        checkExistingAuth()
    }

    private func checkExistingAuth() {
        // Check if we have valid Cognito tokens stored
        Task {
            if await CognitoService.shared.isAuthenticated() {
                // Token exists and is valid
                // Attempt to refresh tokens to ensure they're still valid
                let refreshed = try? await CognitoService.shared.refreshTokens()
                if refreshed == true {
                    // Tokens refreshed successfully, but we need user data
                    // In a production app, you could decode the ID token here
                }
            }
        }
    }

    func signIn(user: User, location: Location? = nil) {
        self.currentUser = user
        self.selectedLocation = location
        self.isAuthenticated = true
    }

    func signOut() {
        // Clear Cognito tokens and AWS credentials
        Task {
            await CognitoService.shared.signOut()
            await AWSCredentialsService.shared.clearCredentials()
            await SecretsManagerService.shared.clearCache()
            await FileMakerService.shared.clearToken()
        }

        // Clear Keychain tokens
        KeychainManager.shared.delete(.authToken)
        KeychainManager.shared.delete(.fileMakerToken)
        KeychainManager.shared.delete(.fileMakerTokenExpiry)

        // Reset state
        isAuthenticated = false
        currentUser = nil
        selectedLocation = nil
    }

    func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaultsManager.shared.isDarkMode = isDarkMode
    }

    func selectLocation(_ location: Location) {
        selectedLocation = location
        UserDefaultsManager.shared.lastSelectedLocationId = location.id
    }
}
