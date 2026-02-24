// DashboardViewModel.swift
// Ingenes
//
// Dashboard business logic

import Foundation
import Combine
import SwiftUI

// MARK: - Models

struct DashboardNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let iconColor: Color
    let timeAgo: String
}

struct ProjectData: Identifiable {
    let id = UUID()
    let month: String
    let count: Int
}

struct BudgetData: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double

    var formattedAmount: String {
        if amount >= 1_000_000 {
            return String(format: "%.1fM", amount / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "%.0fK", amount / 1_000)
        }
        return String(format: "%.0f", amount)
    }
}

enum ProjectPeriod: String, CaseIterable {
    case threeMonths = "3 meses"
    case sixMonths = "6 meses"
    case oneYear = "1 año"
    case allTime = "Todo"

    var monthCount: Int? {
        switch self {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 12
        case .allTime: return nil
        }
    }
}

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published State

    @Published var recentWinners: [Winner] = []
    @Published var proyectos: [Proyecto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSideMenu = false
    @Published var selectedPeriod: ProjectPeriod = .sixMonths

    // MARK: - Dependencies

    private let user: User
    private let fileMakerService = FileMakerService.shared

    // MARK: - Dummy Data for Notifications

    var notifications: [DashboardNotification] {
        [
            DashboardNotification(
                title: "Nuevo pedido recibido",
                message: "Pedido #1234 de Juan García",
                icon: "shippingbox.fill",
                iconColor: .orange,
                timeAgo: "Hace 5 min"
            ),
            DashboardNotification(
                title: "Proyecto actualizado",
                message: "El proyecto 'Renovación Oficina' fue modificado",
                icon: "folder.fill",
                iconColor: .blue,
                timeAgo: "Hace 1 hora"
            ),
            DashboardNotification(
                title: "Pago confirmado",
                message: "Se recibió el pago del pedido #1230",
                icon: "creditcard.fill",
                iconColor: .green,
                timeAgo: "Hace 2 horas"
            ),
            DashboardNotification(
                title: "Recordatorio",
                message: "Tienes 3 pedidos pendientes de revisión",
                icon: "bell.fill",
                iconColor: .purple,
                timeAgo: "Hace 3 horas"
            )
        ]
    }

    // MARK: - Projects Data (from FileMaker)

    /// Generates project counts based on selected period
    var projectsData: [ProjectData] {
        let calendar = Calendar.current
        let today = Date()

        // Get short month names in Spanish
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "es_MX")
        monthFormatter.dateFormat = "MMM"

        // Date formatter for parsing fechaRegistro (MM/dd/yyyy)
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "MM/dd/yyyy"

        // Determine number of months to show
        let monthCount = selectedPeriod.monthCount ?? 12 // Default to 12 for "All Time"

        // Generate months for selected period
        var monthsData: [ProjectData] = []
        for i in (0..<monthCount).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: today) else { continue }
            let monthName = monthFormatter.string(from: monthDate).capitalized
            let monthComponents = calendar.dateComponents([.year, .month], from: monthDate)

            // Count projects registered in this month
            let count = proyectos.filter { proyecto in
                guard let registroDate = inputFormatter.date(from: proyecto.fechaRegistro) else { return false }
                let registroComponents = calendar.dateComponents([.year, .month], from: registroDate)
                return registroComponents.year == monthComponents.year && registroComponents.month == monthComponents.month
            }.count

            monthsData.append(ProjectData(month: monthName, count: count))
        }

        return monthsData
    }

    /// Period label for display
    var periodLabel: String {
        switch selectedPeriod {
        case .threeMonths: return "Últimos 3 meses"
        case .sixMonths: return "Últimos 6 meses"
        case .oneYear: return "Último año"
        case .allTime: return "Últimos 12 meses"
        }
    }

    /// Generates budget totals based on selected period
    var budgetData: [BudgetData] {
        let calendar = Calendar.current
        let today = Date()

        // Get short month names in Spanish
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "es_MX")
        monthFormatter.dateFormat = "MMM"

        // Date formatter for parsing fechaRegistro (MM/dd/yyyy)
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "MM/dd/yyyy"

        // Determine number of months to show
        let monthCount = selectedPeriod.monthCount ?? 12

        // Generate months for selected period
        var monthsData: [BudgetData] = []
        for i in (0..<monthCount).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: today) else { continue }
            let monthName = monthFormatter.string(from: monthDate).capitalized
            let monthComponents = calendar.dateComponents([.year, .month], from: monthDate)

            // Sum presupuesto for projects registered in this month
            let total = proyectos.filter { proyecto in
                guard let registroDate = inputFormatter.date(from: proyecto.fechaRegistro) else { return false }
                let registroComponents = calendar.dateComponents([.year, .month], from: registroDate)
                return registroComponents.year == monthComponents.year && registroComponents.month == monthComponents.month
            }.reduce(0) { $0 + $1.presupuesto }

            monthsData.append(BudgetData(month: monthName, amount: total))
        }

        return monthsData
    }

    /// Total budget across all projects
    var totalBudget: Double {
        proyectos.reduce(0) { $0 + $1.presupuesto }
    }

    /// Formatted total budget string
    var totalBudgetFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalBudget)) ?? "$0"
    }

    var totalProjects: Int {
        proyectos.count
    }

    var activeProjects: Int {
        proyectos.filter { $0.estatus == .activo }.count
    }

    var completedProjects: Int {
        proyectos.filter { $0.estatus == .completado || $0.estatus == .inactivo }.count
    }

    // MARK: - Computed Properties

    var welcomeMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Buenos días"
        case 12..<17:
            return "Buenas tardes"
        default:
            return "Buenas noches"
        }
    }

    var currentMonth: String {
        Date().monthYearString
    }

    /// User's company ID for FileMaker queries
    var companyId: String {
        user.companyId
    }

    // MARK: - Initialization

    init(user: User) {
        self.user = user
    }

    // MARK: - Data Loading

    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Load projects and winners in parallel
        async let projectsTask = loadProjects()
        async let winnersTask = loadWinners()

        await projectsTask
        await winnersTask
    }

    private func loadProjects() async {
        do {
            let fetchedProyectos = try await fileMakerService.fetchProyectos(companyId: user.companyId)
            self.proyectos = fetchedProyectos
            logInfo("DashboardViewModel: Loaded \(fetchedProyectos.count) projects")
        } catch {
            logError("DashboardViewModel: Failed to load projects - \(error.localizedDescription)")
            // Don't clear existing data on error
        }
    }

    private func loadWinners() async {
        do {
            recentWinners = try await fileMakerService.getMonthlyWinners(
                customerId: user.companyId
            )
            // Sort by most recent first and limit to 5
            recentWinners = Array(recentWinners.sorted {
                $0.submittedDate > $1.submittedDate
            }.prefix(5))
        } catch {
            logError("DashboardViewModel: Failed to load winners - \(error.localizedDescription)")
            // Don't clear existing data on error
        }
    }

    func refresh() async {
        await loadDashboardData()
    }
}
