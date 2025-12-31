// LoadingOverlay.swift
// TAG2
//
// Full-screen loading overlay component

import SwiftUI

struct LoadingOverlay: View {
    var message: String?
    var showBackground: Bool = true

    var body: some View {
        ZStack {
            if showBackground {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
            }

            VStack(spacing: AppTheme.spacingMD) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                if let message = message {
                    Text(message)
                        .font(AppTheme.callout)
                        .foregroundColor(.white)
                }
            }
            .padding(AppTheme.spacingXL)
            .background(Color.black.opacity(0.7))
            .cornerRadius(AppTheme.radiusLG)
        }
    }
}

// MARK: - View Extension

extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        ZStack {
            self

            if isLoading {
                LoadingOverlay(message: message)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: AppTheme.animationFast), value: isLoading)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        LoadingOverlay(message: "Loading...")
    }
}
