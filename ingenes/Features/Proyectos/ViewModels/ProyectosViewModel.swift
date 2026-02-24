// ProyectosViewModel.swift
// Ingenes
//
// Proyectos business logic

import Foundation
import SwiftUI
import Combine

// MARK: - Models

enum ProyectoStatus: String, CaseIterable {
    case activo = "ACTIVO"
    case inactivo = "INACTIVO"
    case completado = "COMPLETADO"
    case pausado = "PAUSADO"

    var displayName: String {
        switch self {
        case .activo: return "Activo"
        case .inactivo: return "Inactivo"
        case .completado: return "Completado"
        case .pausado: return "Pausado"
        }
    }

    var color: Color {
        switch self {
        case .activo: return .green
        case .inactivo: return .gray
        case .completado: return .blue
        case .pausado: return .orange
        }
    }

    init(from string: String) {
        self = ProyectoStatus(rawValue: string.uppercased()) ?? .inactivo
    }
}

struct Proyecto: Identifiable, Equatable {
    let id: String
    let idProyecto: Int
    let descripcion: String
    let estatus: ProyectoStatus
    let fechaRegistro: String
    let socioNegocio: String
    let tipoProyecto: String
    let anio: Int
    let pk: String
    let ubicacion: String
    let fechaInicio: String
    let fechaFinal: String
    let idEmpresa: Int
    let pkSocioNegocio: String
    let recId: Int
    let idSN: Int
    let responsable: String
    let pkResponsable: String
    let recordId: String
    let presupuesto: Double

    // Computed properties for UI
    var cliente: String { socioNegocio }
    var fechaCreacion: String { formatDate(fechaRegistro) }
    var statusColor: Color { estatus.color }
    var statusText: String { estatus.displayName }

    /// Formatted budget string for display
    var presupuestoFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: presupuesto)) ?? "$0"
    }

    private func formatDate(_ dateString: String) -> String {
        // Input format: MM/dd/yyyy
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "MM/dd/yyyy"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM yyyy"
        outputFormatter.locale = Locale(identifier: "es_MX")

        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}

@MainActor
class ProyectosViewModel: ObservableObject {
    // MARK: - Published State

    @Published var proyectos: [Proyecto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    // MARK: - Dependencies

    private let fileMakerService = FileMakerService.shared
    private var companyId: String = "2" // Default company ID, will be updated from user

    // MARK: - Computed Properties

    var filteredProyectos: [Proyecto] {
        if searchText.isEmpty {
            return proyectos
        }
        return proyectos.filter { proyecto in
            proyecto.id.localizedCaseInsensitiveContains(searchText) ||
            proyecto.cliente.localizedCaseInsensitiveContains(searchText) ||
            proyecto.descripcion.localizedCaseInsensitiveContains(searchText) ||
            proyecto.tipoProyecto.localizedCaseInsensitiveContains(searchText) ||
            proyecto.ubicacion.localizedCaseInsensitiveContains(searchText)
        }
    }

    var activeCount: Int {
        proyectos.filter { $0.estatus == .activo }.count
    }

    var completedCount: Int {
        proyectos.filter { $0.estatus == .completado || $0.estatus == .inactivo }.count
    }

    // MARK: - Initialization

    init() {
        // Data will be loaded when view appears via loadProyectos()
    }

    // MARK: - Public Methods

    /// Sets the company ID for fetching projects
    func setCompanyId(_ id: String) {
        self.companyId = id
    }

    /// Loads projects from FileMaker API
    func loadProyectos() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let fetchedProyectos = try await fileMakerService.fetchProyectos(companyId: companyId)
            self.proyectos = fetchedProyectos
            logInfo("ProyectosViewModel: Loaded \(fetchedProyectos.count) projects")
        } catch {
            logError("ProyectosViewModel: Failed to load projects - \(error.localizedDescription)")
            errorMessage = "Error al cargar proyectos. Por favor intenta de nuevo."
            // Keep existing data if we have any
        }

        isLoading = false
    }

    /// Refreshes the projects list
    func refresh() async {
        await loadProyectos()
    }
}
