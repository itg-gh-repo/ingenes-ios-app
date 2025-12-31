// AppTheme.swift
// TAG2
//
// Design system: colors, typography, spacing, and styles

import SwiftUI

enum AppTheme {
    // MARK: - Colors

    // Primary blue from web design
    static let primaryBlue = Color(hex: "3B5998")       // Main brand blue
    static let primaryBlueDark = Color(hex: "2D4373")   // Darker shade
    static let primaryBlueLight = Color(hex: "5B7EC2")  // Lighter shade

    // Keep green for backwards compatibility
    static let primaryGreen = Color(hex: "3B5998")      // Now maps to blue
    static let primaryGreenDark = Color(hex: "2D4373")  // Darker shade
    static let primaryGreenLight = Color(hex: "5B7EC2") // Lighter shade

    static let accentColor = Color(hex: "B8860B")       // Gold/Dark gold accent (from logo)
    static let errorColor = Color(hex: "D32F2F")        // Error red
    static let successColor = Color(hex: "388E3C")      // Success green
    static let warningColor = Color(hex: "F57C00")      // Warning orange

    // Info box colors
    static let infoBackground = Color(hex: "E3F2FD")    // Light blue background
    static let infoBorder = Color(hex: "2196F3")        // Blue border

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textMuted = Color.gray

    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)

    // MARK: - Typography

    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let title3 = Font.system(size: 20, weight: .semibold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner Radius

    static let radiusSM: CGFloat = 4
    static let radiusMD: CGFloat = 8
    static let radiusLG: CGFloat = 12
    static let radiusXL: CGFloat = 16
    static let radiusFull: CGFloat = 9999

    // MARK: - Shadows

    static let shadowLight = Color.black.opacity(0.1)
    static let shadowMedium = Color.black.opacity(0.15)
    static let shadowDark = Color.black.opacity(0.2)

    // MARK: - Animation Durations

    static let animationFast: Double = 0.15
    static let animationNormal: Double = 0.3
    static let animationSlow: Double = 0.5
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let isLoading: Bool
    let isDisabled: Bool

    init(isLoading: Bool = false, isDisabled: Bool = false) {
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
            configuration.label
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingMD)
        .padding(.horizontal, AppTheme.spacingLG)
        .background(isDisabled ? Color.gray : AppTheme.primaryGreen)
        .foregroundColor(.white)
        .font(AppTheme.headline)
        .cornerRadius(AppTheme.radiusMD)
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: AppTheme.animationFast), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.spacingMD)
            .padding(.horizontal, AppTheme.spacingLG)
            .background(Color.clear)
            .foregroundColor(AppTheme.primaryGreen)
            .font(AppTheme.headline)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .stroke(AppTheme.primaryGreen, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AppTheme.animationFast), value: configuration.isPressed)
    }
}

struct TextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppTheme.primaryGreen)
            .font(AppTheme.callout)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.backgroundPrimary)
            .cornerRadius(AppTheme.radiusLG)
            .shadow(color: AppTheme.shadowLight, radius: 8, x: 0, y: 2)
    }
}

struct InputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.spacingMD)
            .background(AppTheme.backgroundSecondary)
            .cornerRadius(AppTheme.radiusMD)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    func inputFieldStyle() -> some View {
        modifier(InputFieldModifier())
    }

    func primaryButtonStyle(isLoading: Bool = false, isDisabled: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
    }

    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}
