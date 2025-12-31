// PrimaryButton.swift
// TAG2
//
// Reusable primary button component

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacingSM) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }

                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                }

                Text(title)
            }
        }
        .buttonStyle(PrimaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
        .disabled(isDisabled || isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacingSM) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

struct TextLinkButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacingXS) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(TextButtonStyle())
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    var size: CGFloat = 44
    var foregroundColor: Color = AppTheme.primaryGreen
    var backgroundColor: Color = AppTheme.backgroundSecondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
        }
    }
}

// MARK: - Previews

#Preview("Primary Button") {
    VStack(spacing: 20) {
        PrimaryButton(title: "Sign In", action: {})
        PrimaryButton(title: "Loading...", isLoading: true, action: {})
        PrimaryButton(title: "Disabled", isDisabled: true, action: {})
        PrimaryButton(title: "With Icon", icon: "arrow.right", action: {})
    }
    .padding()
}

#Preview("Secondary Button") {
    VStack(spacing: 20) {
        SecondaryButton(title: "Cancel", action: {})
        SecondaryButton(title: "With Icon", icon: "xmark", action: {})
    }
    .padding()
}

#Preview("Icon Button") {
    HStack(spacing: 20) {
        IconButton(icon: "plus", action: {})
        IconButton(icon: "gear", action: {})
        IconButton(icon: "bell", action: {})
    }
}
