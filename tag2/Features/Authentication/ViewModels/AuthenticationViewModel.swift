// AuthenticationViewModel.swift
// TAG2
//
// Authentication business logic with AWS Cognito

import Foundation
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    // MARK: - Published State

    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var user: User?
    @Published var availableLocations: [Location] = []
    @Published var showLocationPicker = false
    @Published var rememberUsername = false

    // MARK: - Forgot Password State

    @Published var forgotPasswordEmail = ""
    @Published var forgotPasswordLoading = false
    @Published var forgotPasswordSuccess = false
    @Published var forgotPasswordError: String?

    // MARK: - Password Reset Confirmation State

    @Published var showConfirmationCode = false
    @Published var confirmationCode = ""
    @Published var newPassword = ""
    @Published var confirmNewPassword = ""

    // MARK: - Computed Properties

    var canSignIn: Bool {
        !username.trimmed.isEmpty && !password.isEmpty
    }

    var canSendPasswordReset: Bool {
        forgotPasswordEmail.isValidEmail
    }

    var canConfirmPasswordReset: Bool {
        !confirmationCode.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmNewPassword
    }

    /// Check if Cognito is properly configured
    private var isCognitoConfigured: Bool {
        !AppConfig.cognitoUserPoolId.isEmpty &&
        !AppConfig.cognitoClientId.isEmpty &&
        AppConfig.cognitoUserPoolId != "us-east-1_XXXXXXXXX" &&
        AppConfig.cognitoClientId != "xxxxxxxxxxxxxxxxxxxxxxxxxx"
    }

    // MARK: - Initialization

    init() {
        // Load saved username if remember is enabled
        if UserDefaultsManager.shared.rememberUsername {
            rememberUsername = true
            username = UserDefaultsManager.shared.savedUsername ?? ""
        }
    }

    // MARK: - Sign In

    func signIn() async -> Bool {
        guard canSignIn else {
            errorMessage = "Por favor ingresa tu correo y contraseña"
            return false
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Check if Cognito is configured
        guard isCognitoConfigured else {
            errorMessage = "Error de configuración. Contacta al soporte técnico."
            return false
        }

        // Authenticate with Cognito
        return await signInWithCognito()
    }

    // MARK: - Cognito Sign In

    private func signInWithCognito() async -> Bool {
        do {
            // Step 1: Authenticate with AWS Cognito
            let attributes = try await CognitoService.shared.signIn(
                username: username.trimmed,
                password: password
            )

            logInfo("Cognito auth successful - email: \(attributes.email), customerId: \(attributes.customerId)")

            // Step 2: Validate user in FileMaker database
            // Use email and customerId (companyId) from Cognito attributes
            let fileMakerUser = try await FileMakerService.shared.validateUser(
                email: attributes.email,
                companyId: attributes.customerId
            )

            logInfo("FileMaker user loaded - name: \(fileMakerUser.fullName), type: \(fileMakerUser.userType)")

            // Use FileMaker user data
            user = fileMakerUser

            // Save username if remember is enabled
            saveUsernameIfNeeded()

            return true

        } catch let error as CognitoError {
            errorMessage = error.localizedDescription

            // Handle special cases
            if case .newPasswordRequired = error {
                // TODO: Handle new password required flow
            }

            return false
        } catch let error as FileMakerError {
            // User authenticated in Cognito but not found in FileMaker
            logError("FileMakerError: \(error)")
            switch error {
            case .recordNotFound:
                errorMessage = "Usuario no encontrado en el sistema. Contacta al administrador."
            case .invalidResponse(let message):
                errorMessage = message
            case .authenticationFailed:
                errorMessage = "Error de autenticación con FileMaker."
            case .tokenExpired:
                errorMessage = "Sesión de FileMaker expirada. Intenta de nuevo."
            default:
                errorMessage = "Error al validar usuario: \(error.localizedDescription)"
            }
            // Sign out of Cognito since FileMaker validation failed
            await CognitoService.shared.signOut()
            return false
        } catch let error as APIError {
            logError("APIError: \(error)")
            errorMessage = "Error de API: \(error.localizedDescription)"
            await CognitoService.shared.signOut()
            return false
        } catch let error as SecretsManagerError {
            logError("SecretsManagerError: \(error)")
            errorMessage = "Error de configuración: \(error.localizedDescription)"
            await CognitoService.shared.signOut()
            return false
        } catch {
            logError("Authentication error: \(error)")
            logError("Error type: \(type(of: error))")
            errorMessage = "Error: \(type(of: error)) - \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Save Username Helper

    private func saveUsernameIfNeeded() {
        if rememberUsername {
            UserDefaultsManager.shared.savedUsername = username.trimmed
            UserDefaultsManager.shared.rememberUsername = true
        } else {
            UserDefaultsManager.shared.savedUsername = nil
            UserDefaultsManager.shared.rememberUsername = false
        }
    }

    // MARK: - Location Selection

    func selectLocation(_ location: Location) -> Bool {
        // Location selected for multi-location users
        return true
    }

    // MARK: - Forgot Password with Cognito

    func sendPasswordReset() async -> Bool {
        guard canSendPasswordReset else {
            forgotPasswordError = "Por favor ingresa un correo electrónico válido"
            return false
        }

        forgotPasswordLoading = true
        forgotPasswordError = nil
        forgotPasswordSuccess = false

        defer { forgotPasswordLoading = false }

        do {
            try await CognitoService.shared.forgotPassword(username: forgotPasswordEmail.trimmed)
            forgotPasswordSuccess = true
            showConfirmationCode = true
            return true
        } catch let error as CognitoError {
            forgotPasswordError = error.localizedDescription
            return false
        } catch {
            forgotPasswordError = "Error al enviar el código. Por favor intenta de nuevo."
            return false
        }
    }

    // MARK: - Confirm Password Reset

    func confirmPasswordReset() async -> Bool {
        guard canConfirmPasswordReset else {
            forgotPasswordError = "Por favor completa todos los campos correctamente"
            return false
        }

        forgotPasswordLoading = true
        forgotPasswordError = nil

        defer { forgotPasswordLoading = false }

        do {
            try await CognitoService.shared.confirmForgotPassword(
                username: forgotPasswordEmail.trimmed,
                code: confirmationCode.trimmed,
                newPassword: newPassword
            )

            // Reset state after successful password change
            clearForgotPasswordState()
            return true
        } catch let error as CognitoError {
            forgotPasswordError = error.localizedDescription
            return false
        } catch {
            forgotPasswordError = "Error al cambiar la contraseña. Por favor intenta de nuevo."
            return false
        }
    }

    // MARK: - Clear State

    func clearError() {
        errorMessage = nil
    }

    func clearForgotPasswordState() {
        forgotPasswordEmail = ""
        forgotPasswordError = nil
        forgotPasswordSuccess = false
        showConfirmationCode = false
        confirmationCode = ""
        newPassword = ""
        confirmNewPassword = ""
    }
}
