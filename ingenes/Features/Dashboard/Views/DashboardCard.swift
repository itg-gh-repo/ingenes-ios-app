// DashboardCard.swift
// Ingenes
//
// Reusable dashboard action card

import SwiftUI

struct DashboardCard: View {
    let title: String
    let icon: String
    let color: Color
    var subtitle: String? = nil
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.spacingMD) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)

                // Title
                Text(title)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                // Subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.spacingLG)
            .cardStyle()
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: AppTheme.animationFast), value: configuration.isPressed)
    }
}

// MARK: - Large Card Variant

struct LargeDashboardCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var value: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacingMD) {
                // Icon
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(color)
                    )

                // Content
                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    Text(title)
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(subtitle)
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // Value or Chevron
                if let value = value {
                    Text(value)
                        .font(AppTheme.title2)
                        .foregroundColor(color)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            .padding(AppTheme.spacingMD)
            .cardStyle()
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Previews

#Preview("Dashboard Card") {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 16) {
        DashboardCard(
            title: "Proyectos",
            icon: "folder.fill",
            color: .blue,
            action: {}
        )

        DashboardCard(
            title: "Pedidos",
            icon: "shippingbox.fill",
            color: .orange,
            action: {}
        )
    }
    .padding()
}

#Preview("Large Dashboard Card") {
    VStack(spacing: 16) {
        LargeDashboardCard(
            title: "Proyectos Activos",
            subtitle: "Ver todos los proyectos",
            icon: "folder.fill",
            color: .blue,
            value: "15",
            action: {}
        )

        LargeDashboardCard(
            title: "Pedidos Pendientes",
            subtitle: "Ver todos los pedidos",
            icon: "shippingbox.fill",
            color: .orange,
            action: {}
        )
    }
    .padding()
}
