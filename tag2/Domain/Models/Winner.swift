// Winner.swift
// TAG2
//
// Winner model for submitted recognition

import Foundation

struct Winner: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let title: String
    let month: Int
    let year: Int
    let awardId: String
    let awardName: String
    let submittedDate: Date
    let trackingNumber: String?
    let dateShipped: Date?
    let workOrderStatus: String
    let nameplateSize: String?
    let reason: String?

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.month = month
        components.year = year
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    var statusColor: String {
        switch workOrderStatus.lowercased() {
        case "shipped":
            return "green"
        case "processing":
            return "orange"
        case "pending":
            return "yellow"
        default:
            return "gray"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case title = "Title"
        case month = "Month"
        case year = "Year"
        case awardId = "AwardId"
        case awardName = "AwardName"
        case submittedDate = "SubmittedDate"
        case trackingNumber = "TrackingNumber"
        case dateShipped = "DateShipped"
        case workOrderStatus = "WorkOrderStatus"
        case nameplateSize = "NameplateSize"
        case reason = "Reason"
    }
}

// MARK: - Winner Submission Request

struct WinnerSubmission: Encodable {
    let winnerName: String
    let winnerTitle: String
    let awardId: String
    let companyId: String
    let locationId: String
    let month: Int
    let year: Int
    let reason: String?

    var fieldData: [String: Any] {
        var data: [String: Any] = [
            "Name": winnerName,
            "Title": winnerTitle,
            "AwardId": awardId,
            "idEmpresa": companyId,
            "LocationId": locationId,
            "Month": month,
            "Year": year,
            "SubmittedDate": ISO8601DateFormatter().string(from: Date())
        ]

        if let reason = reason, !reason.isEmpty {
            data["Reason"] = reason
        }

        return data
    }
}

// MARK: - Mock Data for Previews

extension Winner {
    static let mock = Winner(
        id: "winner-001",
        name: "Alice Johnson",
        title: "Sales Associate",
        month: 12,
        year: 2024,
        awardId: "award-001",
        awardName: "Employee of the Month",
        submittedDate: Date(),
        trackingNumber: "1234567890",
        dateShipped: Date(),
        workOrderStatus: "Shipped",
        nameplateSize: "Standard",
        reason: "Exceeded sales targets by 150%"
    )

    static let mockList = [
        Winner(
            id: "winner-001",
            name: "Alice Johnson",
            title: "Sales Associate",
            month: 12,
            year: 2024,
            awardId: "award-001",
            awardName: "Employee of the Month",
            submittedDate: Date(),
            trackingNumber: "1234567890",
            dateShipped: Date(),
            workOrderStatus: "Shipped",
            nameplateSize: nil,
            reason: nil
        ),
        Winner(
            id: "winner-002",
            name: "Bob Smith",
            title: "Team Lead",
            month: 11,
            year: 2024,
            awardId: "award-001",
            awardName: "Employee of the Month",
            submittedDate: Date().adding(days: -30),
            trackingNumber: nil,
            dateShipped: nil,
            workOrderStatus: "Processing",
            nameplateSize: nil,
            reason: nil
        ),
        Winner(
            id: "winner-003",
            name: "Carol White",
            title: "Customer Service Rep",
            month: 10,
            year: 2024,
            awardId: "award-002",
            awardName: "Team Player Award",
            submittedDate: Date().adding(days: -60),
            trackingNumber: "0987654321",
            dateShipped: Date().adding(days: -55),
            workOrderStatus: "Shipped",
            nameplateSize: nil,
            reason: nil
        )
    ]
}
