// TAG2App.swift
// TAG2
//
// Main app entry point

import SwiftUI

@main
struct TAG2App: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}
