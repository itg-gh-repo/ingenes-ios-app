// DashboardViewModel.swift
// Ingenes
//
// Dashboard business logic for fertility clinic

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

struct PacientesAtendidosData: Identifiable {
    let id = UUID()
    let month: String
    let count: Int
}

struct TratamientoTipoData: Identifiable {
    let id = UUID()
    let tipo: String
    let count: Int
    let color: Color
}

enum ClinicPeriod: String, CaseIterable {
    case threeMonths = "3 meses"
    case sixMonths = "6 meses"
    case oneYear = "1 año"
    case allTime = "Todo"

    var monthCount: Int {
        switch self {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 12
        case .allTime: return 12
        }
    }
}

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPeriod: ClinicPeriod = .sixMonths

    // MARK: - Dummy Data

    @Published var pacientesData: [PacientesAtendidosData] = []
    @Published var tratamientosTipoData: [TratamientoTipoData] = []

    // MARK: - Dependencies

    private let user: User

    // MARK: - Clinic Stats

    var totalPacientesMes: Int { 48 }
    var citasHoy: Int { 12 }
    var tasaExito: Double { 62.5 }

    var tratamientosEnCurso: Int {
        Tratamiento.mockList.filter { $0.resultado == .enCurso }.count
    }

    var tratamientosPositivos: Int {
        Tratamiento.mockList.filter { $0.resultado == .positivo }.count
    }

    var notasPendientes: Int {
        NotaMedica.mockList.filter { $0.estatus == .pendiente }.count
    }

    // MARK: - Notifications

    var notifications: [DashboardNotification] {
        [
            DashboardNotification(
                title: "3 notas médicas pendientes",
                message: "Tienes notas por completar del día de hoy",
                icon: "stethoscope",
                iconColor: Color(hex: "4A90D9"),
                timeAgo: "Hace 10 min"
            ),
            DashboardNotification(
                title: "Ciclo de estimulación iniciado",
                message: "Paciente Ana Martínez - Día 1 de estimulación",
                icon: "heart.text.clipboard",
                iconColor: .pink,
                timeAgo: "Hace 1 hora"
            ),
            DashboardNotification(
                title: "Resultados de laboratorio disponibles",
                message: "Beta-HCG de María García López lista",
                icon: "flask.fill",
                iconColor: Color(hex: "388E3C"),
                timeAgo: "Hace 2 horas"
            ),
            DashboardNotification(
                title: "Cita reprogramada",
                message: "Valentina Díaz - nueva fecha: mañana 10:00 AM",
                icon: "calendar.badge.clock",
                iconColor: .orange,
                timeAgo: "Hace 3 horas"
            )
        ]
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

    // MARK: - Initialization

    init(user: User) {
        self.user = user
    }

    // MARK: - Data Loading

    func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        loadPacientesData()
        loadTratamientosTipoData()
    }

    private func loadPacientesData() {
        let calendar = Calendar.current
        let today = Date()
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "es_MX")
        monthFormatter.dateFormat = "MMM"

        // Monthly patient counts (realistic dummy data)
        let monthlyCounts = [42, 38, 55, 47, 61, 48, 52, 45, 58, 50, 44, 53]
        let monthCount = selectedPeriod.monthCount

        var data: [PacientesAtendidosData] = []
        for i in (0..<monthCount).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: today) else { continue }
            let monthName = monthFormatter.string(from: monthDate).capitalized
            let count = monthlyCounts[i % monthlyCounts.count]
            data.append(PacientesAtendidosData(month: monthName, count: count))
        }
        pacientesData = data
    }

    private func loadTratamientosTipoData() {
        tratamientosTipoData = [
            TratamientoTipoData(tipo: "FIV Propios", count: 35, color: Color(hex: "4A90D9")),
            TratamientoTipoData(tipo: "Ovodonación", count: 25, color: Color(hex: "E91E63")),
            TratamientoTipoData(tipo: "IAD", count: 15, color: Color(hex: "9C27B0")),
            TratamientoTipoData(tipo: "Descongelación", count: 12, color: Color(hex: "00BCD4")),
            TratamientoTipoData(tipo: "Otros", count: 13, color: Color(hex: "FF9800")),
        ]
    }

    func refresh() async {
        await loadDashboardData()
    }
}
