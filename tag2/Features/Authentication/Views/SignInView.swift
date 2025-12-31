// SignInView.swift
// TAG2
//
// Sign in screen - supports Light and Dark Mode

import SwiftUI
import Combine

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthenticationViewModel()
    @FocusState private var focusedField: Field?
    @Environment(\.colorScheme) var colorScheme

    private enum Field {
        case email
        case password
    }

    // MARK: - Adaptive Colors

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color(hex: "F2F2F7")
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "2C2C2E") : Color.white
    }

    private var inputBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F8F9FA")
    }

    private var inputTextColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "1A1A1A")
    }

    private var placeholderColor: Color {
        colorScheme == .dark ? Color.gray : Color.gray.opacity(0.6)
    }

    private var titleTextColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "1A1A1A")
    }

    private var subtitleTextColor: Color {
        colorScheme == .dark ? Color.gray : Color(hex: "6B7280")
    }

    private var inputBorderColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: max(geometry.size.height * 0.08, 40))

                    // Logo and Branding
                    logoSection
                        .padding(.bottom, AppTheme.spacingXL)

                    // Welcome Text
                    welcomeSection
                        .padding(.bottom, AppTheme.spacingXL)

                    // Form Card
                    VStack(spacing: AppTheme.spacingLG) {
                        // Form Fields
                        formSection

                        // Remember & Forgot Password Row
                        optionsRow

                        // Sign In Button
                        signInButton

                        // Error Message
                        errorSection
                    }
                    .padding(AppTheme.spacingLG)
                    .background(cardBackgroundColor)
                    .cornerRadius(AppTheme.radiusXL)
                    .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.08), radius: 20, x: 0, y: 4)

                    Spacer()
                        .frame(height: AppTheme.spacingXL)
                }
                .padding(.horizontal, AppTheme.spacingLG)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showLocationPicker) {
            if let user = viewModel.user {
                LocationSelectionView(
                    locations: viewModel.availableLocations,
                    onSelect: { location in
                        appState.signIn(user: user, location: location)
                    }
                )
            }
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: AppTheme.spacingSM) {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)

            Text("TALLER DE ARQUITECTURA")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.accentColor)
                .tracking(2)
        }
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(spacing: AppTheme.spacingSM) {
            Text("Bienvenido")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(titleTextColor)

            Text("Ingresa tus credenciales para acceder al sistema")
                .font(AppTheme.subheadline)
                .foregroundColor(subtitleTextColor)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: AppTheme.spacingMD) {
            // Email Field
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "envelope")
                    .foregroundColor(focusedField == .email ? AppTheme.primaryBlue : placeholderColor)
                    .frame(width: 20)

                TextField("Correo Electrónico", text: $viewModel.username)
                    .foregroundColor(inputTextColor)
                    .tint(AppTheme.primaryBlue)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, 16)
            .background(inputBackgroundColor)
            .cornerRadius(AppTheme.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLG)
                    .stroke(focusedField == .email ? AppTheme.primaryBlue : inputBorderColor, lineWidth: focusedField == .email ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)

            // Password Field
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "lock")
                    .foregroundColor(focusedField == .password ? AppTheme.primaryBlue : placeholderColor)
                    .frame(width: 20)

                SecureField("Contraseña", text: $viewModel.password)
                    .foregroundColor(inputTextColor)
                    .tint(AppTheme.primaryBlue)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { signIn() }
            }
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, 16)
            .background(inputBackgroundColor)
            .cornerRadius(AppTheme.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLG)
                    .stroke(focusedField == .password ? AppTheme.primaryBlue : inputBorderColor, lineWidth: focusedField == .password ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    // MARK: - Options Row (Remember + Forgot Password)

    private var optionsRow: some View {
        HStack {
            // Remember Session Checkbox
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.rememberUsername.toggle()
                }
            }) {
                HStack(spacing: AppTheme.spacingSM) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(viewModel.rememberUsername ? AppTheme.primaryBlue : placeholderColor, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(viewModel.rememberUsername ? AppTheme.primaryBlue : Color.clear)
                            )

                        if viewModel.rememberUsername {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    Text("Recordar sesión")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(subtitleTextColor)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // Forgot Password Link
            NavigationLink(destination: ForgotPasswordView()) {
                Text("¿Olvidaste tu contraseña?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
            }
        }
    }

    // MARK: - Sign In Button

    private var signInButton: some View {
        Button(action: signIn) {
            HStack(spacing: AppTheme.spacingSM) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                Text("Iniciar Sesión")
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if viewModel.canSignIn {
                        LinearGradient(
                            colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .foregroundColor(.white)
            .cornerRadius(AppTheme.radiusLG)
            .shadow(color: viewModel.canSignIn ? AppTheme.primaryBlue.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!viewModel.canSignIn || viewModel.isLoading)
        .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
    }

    // MARK: - Error Section

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.errorColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .transition(.opacity)
        }
    }

    // MARK: - Actions

    private func signIn() {
        focusedField = nil

        Task {
            let success = await viewModel.signIn()
            if success, let user = viewModel.user {
                appState.signIn(user: user)
            }
        }
    }
}

// MARK: - Web Style Input Field Modifier

struct WebStyleInputField: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    private var inputBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "3A3A3C") : Color.white
    }

    private var inputTextColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "1A1A1A")
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.4) : Color.gray.opacity(0.3)
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(inputTextColor)
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, 14)
            .background(inputBackgroundColor)
            .cornerRadius(AppTheme.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignInView()
    }
    .environmentObject(AppState())
}

#Preview("Dark Mode") {
    NavigationStack {
        SignInView()
    }
    .environmentObject(AppState())
    .preferredColorScheme(.dark)
}
