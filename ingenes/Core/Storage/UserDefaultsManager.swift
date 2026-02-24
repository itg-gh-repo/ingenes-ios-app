// UserDefaultsManager.swift
// Ingenes
//
// User preferences storage

import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Keys

    private enum Keys: String {
        case isDarkMode
        case notification20Day
        case notification10Day
        case notification3Day
        case notification1Day
        case lastSelectedLocationId
        case hasCompletedOnboarding
        case rememberUsername
        case savedUsername
    }

    // MARK: - Theme

    var isDarkMode: Bool {
        get { defaults.bool(forKey: Keys.isDarkMode.rawValue) }
        set { defaults.set(newValue, forKey: Keys.isDarkMode.rawValue) }
    }

    // MARK: - Notifications

    var notification20Day: Bool {
        get { defaults.object(forKey: Keys.notification20Day.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.notification20Day.rawValue) }
    }

    var notification10Day: Bool {
        get { defaults.object(forKey: Keys.notification10Day.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.notification10Day.rawValue) }
    }

    var notification3Day: Bool {
        get { defaults.object(forKey: Keys.notification3Day.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.notification3Day.rawValue) }
    }

    var notification1Day: Bool {
        get { defaults.object(forKey: Keys.notification1Day.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.notification1Day.rawValue) }
    }

    // MARK: - Location

    var lastSelectedLocationId: String? {
        get { defaults.string(forKey: Keys.lastSelectedLocationId.rawValue) }
        set { defaults.set(newValue, forKey: Keys.lastSelectedLocationId.rawValue) }
    }

    // MARK: - Onboarding

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding.rawValue) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding.rawValue) }
    }

    // MARK: - Remember Username

    var rememberUsername: Bool {
        get { defaults.bool(forKey: Keys.rememberUsername.rawValue) }
        set { defaults.set(newValue, forKey: Keys.rememberUsername.rawValue) }
    }

    var savedUsername: String? {
        get { defaults.string(forKey: Keys.savedUsername.rawValue) }
        set { defaults.set(newValue, forKey: Keys.savedUsername.rawValue) }
    }

    // MARK: - Clear All

    func clearAll() {
        guard let domain = Bundle.main.bundleIdentifier else {
            return
        }
        defaults.removePersistentDomain(forName: domain)
    }
}
