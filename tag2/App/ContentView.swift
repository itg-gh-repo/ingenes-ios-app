// ContentView.swift
// TAG2
//
// Root navigation view with splash screen

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if appState.isAuthenticated {
                DashboardView()
                    .transition(.opacity)
            } else {
                NavigationStack {
                    SignInView()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: AppTheme.animationNormal), value: showSplash)
        .animation(.easeInOut(duration: AppTheme.animationNormal), value: appState.isAuthenticated)
        .onAppear {
            // Show splash for configured duration
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.splashDuration) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.6
    @State private var ring2Opacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            // Clean white background
            Color.white
                .ignoresSafeArea()

            // Main content - vertically centered
            VStack(spacing: 0) {
                Spacer()

                // Logo + Rings + Text group - all centered together
                VStack(spacing: AppTheme.spacingLG) {
                    // Logo with animated rings
                    ZStack {
                        // Outer ring
                        Circle()
                            .stroke(AppTheme.primaryGreen.opacity(0.1), lineWidth: 2)
                            .frame(width: 200, height: 200)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)

                        // Inner ring
                        Circle()
                            .stroke(AppTheme.primaryGreen.opacity(0.15), lineWidth: 1.5)
                            .frame(width: 160, height: 160)
                            .scaleEffect(ring2Scale)
                            .opacity(ring2Opacity)

                        // Decorative arc
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(
                                AppTheme.primaryGreen.opacity(0.3),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)

                        // Logo with shimmer effect
                        ZStack {
                            // Main logo
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .scaleEffect(logoScale)
                                .opacity(logoOpacity)

                            // Shimmer overlay
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            .white.opacity(0.4),
                                            .clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 50, height: 150)
                                .offset(x: shimmerOffset)
                                .mask(
                                    Image("logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 120)
                                )
                        }
                    }
                    .frame(width: 200, height: 200)

                    // Brand text
                    Text("TALLER DE ARQUITECTURA")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(2.5)
                        .opacity(textOpacity)
                }

                Spacer()

                // Loading indicator at bottom
                HStack(spacing: AppTheme.spacingSM) {
                    LoadingDot(delay: 0)
                    LoadingDot(delay: 0.15)
                    LoadingDot(delay: 0.3)
                }
                .opacity(textOpacity)
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            // Logo entrance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Rings animation
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                ring2Scale = 1.0
                ring2Opacity = 1.0
            }

            // Text fade in
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                textOpacity = 1.0
            }

            // Shimmer effect
            withAnimation(.easeInOut(duration: 1.2).delay(0.6)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Loading Dot

struct LoadingDot: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(AppTheme.primaryGreen)
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .opacity(isAnimating ? 1.0 : 0.3)
            .animation(
                Animation
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Previews

#Preview("Content View - Signed Out") {
    ContentView()
        .environmentObject(AppState())
}

#Preview("Splash View") {
    SplashView()
}
