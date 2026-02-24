// ForgotPasswordView.swift
// Ingenes
//
// Password recovery screen with AWS Cognito

import SwiftUI
import Combine

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AuthenticationViewModel()
    @FocusState private var focusedField: Field?
    @State private var passwordResetComplete = false

    enum Field {
        case email, code, newPassword, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLG) {
                Spacer()
                    .frame(height: AppTheme.spacingXL)

                // Header
                headerSection

                if passwordResetComplete {
                    // Password reset complete
                    passwordResetCompleteSection
                } else if viewModel.showConfirmationCode {
                    // Confirmation code entry
                    confirmationCodeSection
                } else {
                    // Email entry
                    emailSection
                    sendButton
                }

                // Error Message
                errorSection

                Spacer()
            }
            .padding(.horizontal, AppTheme.spacingLG)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Restablecer Contraseña")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: viewModel.showConfirmationCode)
        .animation(.easeInOut, value: passwordResetComplete)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Image(systemName: headerIcon)
                .font(.system(size: 60))
                .foregroundColor(headerColor)

            Text(headerTitle)
                .font(AppTheme.title2)
                .foregroundColor(AppTheme.textPrimary)

            Text(headerSubtitle)
                .font(AppTheme.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, AppTheme.spacingLG)
    }

    private var headerIcon: String {
        if passwordResetComplete {
            return "checkmark.circle.fill"
        } else if viewModel.showConfirmationCode {
            return "key.fill"
        } else {
            return "envelope.badge.shield.half.filled"
        }
    }

    private var headerColor: Color {
        if passwordResetComplete {
            return AppTheme.successColor
        } else {
            return AppTheme.primaryBlue
        }
    }

    private var headerTitle: String {
        if passwordResetComplete {
            return "¡Contraseña Actualizada!"
        } else if viewModel.showConfirmationCode {
            return "Ingresa el Código"
        } else {
            return "¿Olvidaste tu contraseña?"
        }
    }

    private var headerSubtitle: String {
        if passwordResetComplete {
            return "Tu contraseña ha sido restablecida exitosamente. Ya puedes iniciar sesión con tu nueva contraseña."
        } else if viewModel.showConfirmationCode {
            return "Ingresa el código de 6 dígitos que enviamos a tu correo y crea una nueva contraseña."
        } else {
            return "Ingresa tu correo electrónico y te enviaremos un código para restablecer tu contraseña."
        }
    }

    // MARK: - Email Section

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
            Text("Correo Electrónico")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textSecondary)

            TextField("Ingresa tu correo", text: $viewModel.forgotPasswordEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .submitLabel(.send)
                .onSubmit { sendReset() }
                .modifier(WebStyleInputField())
        }
    }

    // MARK: - Confirmation Code Section

    private var confirmationCodeSection: some View {
        VStack(spacing: AppTheme.spacingMD) {
            // Code field
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text("Código de Verificación")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.textSecondary)

                TextField("Código de 6 dígitos", text: $viewModel.confirmationCode)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .code)
                    .modifier(WebStyleInputField())
                    .onChange(of: viewModel.confirmationCode) { _, newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            viewModel.confirmationCode = String(newValue.prefix(6))
                        }
                    }
            }

            // New password field
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text("Nueva Contraseña")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.textSecondary)

                SecureField("Mínimo 8 caracteres", text: $viewModel.newPassword)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .newPassword)
                    .modifier(WebStyleInputField())
            }

            // Confirm password field
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text("Confirmar Contraseña")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.textSecondary)

                SecureField("Repite tu contraseña", text: $viewModel.confirmNewPassword)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .modifier(WebStyleInputField())
            }

            // Password requirements
            passwordRequirements

            // Confirm button
            confirmButton

            // Resend code button
            Button("¿No recibiste el código? Reenviar") {
                Task {
                    await viewModel.sendPasswordReset()
                }
            }
            .font(AppTheme.caption)
            .foregroundColor(AppTheme.primaryBlue)
            .disabled(viewModel.forgotPasswordLoading)
        }
    }

    private var passwordRequirements: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
            PasswordRequirementRow(
                text: "Mínimo 8 caracteres",
                isMet: viewModel.newPassword.count >= 8
            )
            PasswordRequirementRow(
                text: "Las contraseñas coinciden",
                isMet: !viewModel.newPassword.isEmpty && viewModel.newPassword == viewModel.confirmNewPassword
            )
        }
        .padding(.vertical, AppTheme.spacingSM)
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button(action: sendReset) {
            HStack(spacing: AppTheme.spacingSM) {
                if viewModel.forgotPasswordLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text("Enviar Código")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.canSendPasswordReset ? AppTheme.primaryBlue : Color.gray)
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(AppTheme.radiusMD)
        }
        .disabled(!viewModel.canSendPasswordReset || viewModel.forgotPasswordLoading)
        .padding(.top, AppTheme.spacingSM)
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button(action: confirmReset) {
            HStack(spacing: AppTheme.spacingSM) {
                if viewModel.forgotPasswordLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text("Cambiar Contraseña")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.canConfirmPasswordReset ? AppTheme.primaryBlue : Color.gray)
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(AppTheme.radiusMD)
        }
        .disabled(!viewModel.canConfirmPasswordReset || viewModel.forgotPasswordLoading)
        .padding(.top, AppTheme.spacingSM)
    }

    // MARK: - Password Reset Complete Section

    private var passwordResetCompleteSection: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Button("Volver al Inicio de Sesión") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.primaryGreen)
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(AppTheme.radiusMD)
        }
        .padding(.top, AppTheme.spacingLG)
    }

    // MARK: - Error Section

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.forgotPasswordError {
            Text(error)
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.errorColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .transition(.opacity)
        }
    }

    // MARK: - Actions

    private func sendReset() {
        focusedField = nil

        Task {
            await viewModel.sendPasswordReset()
        }
    }

    private func confirmReset() {
        focusedField = nil

        Task {
            let success = await viewModel.confirmPasswordReset()
            if success {
                passwordResetComplete = true
            }
        }
    }
}

// MARK: - Password Requirement Row

struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: AppTheme.spacingXS) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? AppTheme.successColor : AppTheme.textMuted)
                .font(.system(size: 14))

            Text(text)
                .font(AppTheme.caption)
                .foregroundColor(isMet ? AppTheme.textPrimary : AppTheme.textMuted)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
