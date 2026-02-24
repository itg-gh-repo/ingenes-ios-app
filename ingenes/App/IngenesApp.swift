// IngenesApp.swift
// Ingenes
//
// Main app entry point

import SwiftUI

@main
struct IngenesApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}
