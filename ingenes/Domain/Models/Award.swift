// Award.swift
// Ingenes
//
// Award model for recognition programs

import Foundation

struct Award: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let description: String
    let programType: ProgramType
    let startDate: Date?
    let endDate: Date?
    let isActive: Bool
    let requiredFields: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case description = "Description"
        case programType = "ProgramType"
        case startDate = "StartDate"
        case endDate = "EndDate"
        case isActive = "IsActive"
        case requiredFields = "RequiredFields"
    }

    var isCurrentlyActive: Bool {
        guard isActive else { return false }

        let now = Date()

        if let start = startDate, now < start {
            return false
        }

        if let end = endDate, now > end {
            return false
        }

        return true
    }
}

enum ProgramType: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case perpetual = "Perpetual"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .monthly:
            return "calendar"
        case .quarterly:
            return "calendar.badge.clock"
        case .perpetual:
            return "star.fill"
        }
    }
}

// MARK: - Mock Data for Previews

extension Award {
    static let mock = Award(
        id: "award-001",
        name: "Employee of the Month",
        description: "Monthly recognition for outstanding performance",
        programType: .monthly,
        startDate: nil,
        endDate: nil,
        isActive: true,
        requiredFields: ["winnerName", "winnerTitle", "reason"]
    )

    static let mockList = [
        Award(
            id: "award-001",
            name: "Employee of the Month",
            description: "Monthly recognition for outstanding performance",
            programType: .monthly,
            startDate: nil,
            endDate: nil,
            isActive: true,
            requiredFields: nil
        ),
        Award(
            id: "award-002",
            name: "Team Player Award",
            description: "For exceptional teamwork and collaboration",
            programType: .monthly,
            startDate: nil,
            endDate: nil,
            isActive: true,
            requiredFields: nil
        ),
        Award(
            id: "award-003",
            name: "Quarterly Star",
            description: "Quarterly recognition for top performers",
            programType: .quarterly,
            startDate: nil,
            endDate: nil,
            isActive: true,
            requiredFields: nil
        ),
        Award(
            id: "award-004",
            name: "Years of Service",
            description: "Celebrating dedication and loyalty",
            programType: .perpetual,
            startDate: nil,
            endDate: nil,
            isActive: true,
            requiredFields: nil
        )
    ]
}
