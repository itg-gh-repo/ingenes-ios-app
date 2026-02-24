// SideMenuView.swift
// Ingenes
//
// Side navigation menu

import SwiftUI

// MARK: - Menu Navigation Destination

enum MenuDestination {
    case dashboard
    case notasMedicas
    case tratamientos
}

struct SideMenuView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var onNavigate: ((MenuDestination) -> Void)?

    var body: some View {
        NavigationStack {
            List {
                // User Info Header
                userInfoSection

                // Features Section
                featuresSection

                // Account Section
                accountSection

                // App Info Section
                appInfoSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Menú")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }

    // MARK: - User Info Section

    private var userInfoSection: some View {
        Section {
            if let user = appState.currentUser {
                HStack(spacing: AppTheme.spacingMD) {
                    // Avatar with user initials
                    Circle()
                        .fill(AppTheme.primaryGreen.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(userInitials(for: user))
                                .font(AppTheme.headline)
                                .foregroundColor(AppTheme.primaryGreen)
                        )

                    VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                        Text(user.fullName)
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        Text(user.userTypeDisplayName)
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textSecondary)

                        Text(user.email)
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .padding(.vertical, AppTheme.spacingSM)
            }
        }
    }

    /// Get initials from user name
    private func userInitials(for user: User) -> String {
        let first = user.firstName.prefix(1).uppercased()
        let last = user.lastName.prefix(1).uppercased()
        if first.isEmpty && last.isEmpty {
            return String(user.username.prefix(2)).uppercased()
        }
        return first + last
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        Section("Funciones") {
            MenuRow(icon: "chart.bar.fill", title: "Dashboard", color: .blue) {
                dismiss()
                onNavigate?(.dashboard)
            }

            MenuRow(icon: "stethoscope", title: "Notas Médicas", color: Color(hex: "4A90D9")) {
                dismiss()
                onNavigate?(.notasMedicas)
            }

            MenuRow(icon: "heart.text.clipboard", title: "Tratamientos", color: .pink) {
                dismiss()
                onNavigate?(.tratamientos)
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Cuenta") {
            MenuRow(icon: "gearshape.fill", title: "Configuración", color: .gray) {
                dismiss()
                // TODO: Navigate to Settings
            }

            // Dark Mode Toggle
            Toggle(isOn: Binding(
                get: { appState.isDarkMode },
                set: { _ in appState.toggleDarkMode() }
            )) {
                HStack(spacing: AppTheme.spacingMD) {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24)

                    Text("Modo Oscuro")
                        .font(AppTheme.body)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))

            // Sign Out
            Button {
                appState.signOut()
                dismiss()
            } label: {
                HStack(spacing: AppTheme.spacingMD) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .frame(width: 24)

                    Text("Cerrar Sesión")
                        .font(AppTheme.body)
                        .foregroundColor(.red)

                    Spacer()
                }
            }
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: AppTheme.spacingXS) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)

                    Text("Versión \(AppConfig.appVersion)")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Menu Row

struct MenuRow: View {
    let icon: String
    let title: String
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: AppTheme.spacingMD) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .font(AppTheme.body)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.textMuted)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SideMenuView()
        .environmentObject(AppState())
}
