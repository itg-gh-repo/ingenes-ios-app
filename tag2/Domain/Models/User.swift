// User.swift
// TAG2
//
// User model representing an authenticated user

import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let companyId: String
    let userType: String
    let username: String
    let phone: String?
    let recordId: String?

    var fullName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            return username
        }
        // Format name nicely (capitalize first letter of each word)
        return name.capitalized
    }

    /// User type display name (e.g., "Administrador", "Usuario")
    var userTypeDisplayName: String {
        userType
    }

    /// Check if user is an administrator
    var isAdmin: Bool {
        userType.lowercased() == "administrador" || userType.lowercased() == "admin"
    }
}

// MARK: - Mock Data for Previews

extension User {
    static let mock = User(
        id: "1",
        firstName: "OSCAR",
        lastName: "SANCHEZ MERIDA",
        email: "osanchez@itgroup.mx",
        companyId: "2",
        userType: "Administrador",
        username: "admin_prueba",
        phone: "5566779900",
        recordId: "12345"
    )
}
