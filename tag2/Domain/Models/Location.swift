// Location.swift
// TAG2
//
// Location model for multi-location users

import Foundation

struct Location: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let storeName: String
    let status: String
    let customerId: String

    var isActive: Bool {
        status.lowercased() == "active"
    }

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case storeName = "StoreName"
        case status = "Status"
        case customerId = "CustomerId"
    }
}

// MARK: - Mock Data for Previews

extension Location {
    static let mock = Location(
        id: "loc-001",
        name: "Downtown Store",
        storeName: "TAG2 Downtown",
        status: "Active",
        customerId: "CUST-001"
    )

    static let mockList = [
        Location(id: "loc-001", name: "Downtown Store", storeName: "TAG2 Downtown", status: "Active", customerId: "CUST-001"),
        Location(id: "loc-002", name: "Uptown Store", storeName: "TAG2 Uptown", status: "Active", customerId: "CUST-002"),
        Location(id: "loc-003", name: "Mall Location", storeName: "TAG2 Mall", status: "Active", customerId: "CUST-003")
    ]
}
