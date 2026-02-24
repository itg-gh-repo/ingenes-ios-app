// PedidosViewModel.swift
// Ingenes
//
// Pedidos business logic

import Foundation
import SwiftUI
import Combine

// MARK: - Models

enum PedidoStatus: String, CaseIterable {
    case porAutorizar = "Por Autorizar"
    case autorizado = "Autorizado"
    case pagado = "Pagado"
    case cancelado = "Cancelado"

    var displayName: String {
        rawValue
    }

    var color: Color {
        switch self {
        case .porAutorizar: return .orange
        case .autorizado: return .blue
        case .pagado: return .green
        case .cancelado: return .red
        }
    }

    var icon: String {
        switch self {
        case .porAutorizar: return "exclamationmark.circle.fill"
        case .autorizado: return "checkmark.circle.fill"
        case .pagado: return "dollarsign.circle.fill"
        case .cancelado: return "xmark.circle.fill"
        }
    }

    init(from string: String) {
        let normalized = string.trimmingCharacters(in: .whitespaces).lowercased()
        switch normalized {
        case "por autorizar": self = .porAutorizar
        case "autorizado": self = .autorizado
        case "pagado": self = .pagado
        case "cancelado": self = .cancelado
        default: self = .porAutorizar
        }
    }
}

struct Pedido: Identifiable, Equatable {
    let id: String
    let idPedido: Int
    let fecha: String
    let fechaCreacion: String
    let usuario: String
    let proveedor: String
    let proyecto: String
    let proyectoDescripcion: String
    let proyectoUbicacion: String
    let concepto: String
    let tipoPedido: String
    let clase: String
    let condicionesPago: String
    let moneda: String
    let observaciones: String
    let total: Double
    let pagado: Double
    let adeudo: Double
    let status: PedidoStatus
    let recordId: String
    let cotizacionURL: String   // URL to the quotation PDF
    let facturaPDFURL: String   // URL to the invoice PDF
    let facturaXMLURL: String   // URL to the invoice XML (CFDI)
    let comprobacionURL: String // URL to the verification/proof PDF

    var statusColor: Color {
        status.color
    }

    var statusText: String {
        status.displayName
    }

    var statusIcon: String {
        status.icon
    }

    var totalFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: total)) ?? "$\(total)"
    }

    var pagadoFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: pagado)) ?? "$\(pagado)"
    }

    var adeudoFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: adeudo)) ?? "$\(adeudo)"
    }

    var fechaFormatted: String {
        formatDate(fecha)
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
class PedidosViewModel: ObservableObject {
    // MARK: - Published State

    @Published var pedidos: [Pedido] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    // MARK: - Filter State

    @Published var selectedStatus: PedidoStatus?
    @Published var selectedProveedor: String?
    @Published var showFilters = false

    // MARK: - Dependencies

    private let fileMakerService = FileMakerService.shared
    private var companyId: String = "2" // Default company ID, will be updated from user

    // MARK: - Computed Properties

    var filteredPedidos: [Pedido] {
        var result = pedidos

        // Search filter
        if !searchText.isEmpty {
            result = result.filter { pedido in
                pedido.id.localizedCaseInsensitiveContains(searchText) ||
                pedido.usuario.localizedCaseInsensitiveContains(searchText) ||
                pedido.proveedor.localizedCaseInsensitiveContains(searchText) ||
                pedido.proyecto.localizedCaseInsensitiveContains(searchText) ||
                pedido.concepto.localizedCaseInsensitiveContains(searchText) ||
                pedido.tipoPedido.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Status filter
        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }

        // Proveedor filter
        if let proveedor = selectedProveedor {
            result = result.filter { $0.proveedor == proveedor }
        }

        return result
    }

    var uniqueProveedores: [String] {
        Array(Set(pedidos.compactMap { $0.proveedor.isEmpty ? nil : $0.proveedor })).sorted()
    }

    /// Returns unique statuses that exist in the current pedidos data, sorted by a logical order
    var uniqueStatuses: [PedidoStatus] {
        let statusOrder: [PedidoStatus] = [.porAutorizar, .autorizado, .pagado, .cancelado]
        let existingStatuses = Set(pedidos.map { $0.status })
        return statusOrder.filter { existingStatuses.contains($0) }
    }

    var pendingCount: Int {
        pedidos.filter { $0.status == .porAutorizar }.count
    }

    var inProgressCount: Int {
        pedidos.filter { $0.status == .autorizado }.count
    }

    var completedCount: Int {
        pedidos.filter { $0.status == .pagado }.count
    }

    var totalAmount: Double {
        filteredPedidos.reduce(0) { $0 + $1.total }
    }

    var totalAmountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "$\(totalAmount)"
    }

    /// Total amount for all pedidos (unfiltered)
    var allPedidosTotalAmount: Double {
        pedidos.reduce(0) { $0 + $1.total }
    }

    var hasActiveFilters: Bool {
        selectedStatus != nil || selectedProveedor != nil
    }

    // MARK: - Initialization

    init() {
        // Data will be loaded when view appears via loadPedidos()
    }

    // MARK: - Public Methods

    /// Sets the company ID for fetching pedidos
    func setCompanyId(_ id: String) {
        self.companyId = id
    }

    // MARK: - Actions

    func clearFilters() {
        selectedStatus = nil
        selectedProveedor = nil
    }

    // MARK: - Data Loading

    /// Loads pedidos from FileMaker API
    func loadPedidos() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let fetchedPedidos = try await fileMakerService.fetchPedidos(companyId: companyId)
            self.pedidos = fetchedPedidos
            logInfo("PedidosViewModel: Loaded \(fetchedPedidos.count) pedidos")
        } catch {
            logError("PedidosViewModel: Failed to load pedidos - \(error.localizedDescription)")
            errorMessage = "Error al cargar pedidos. Por favor intenta de nuevo."
            // Keep existing data if we have any
        }

        isLoading = false
    }

    /// Refreshes the pedidos list
    func refresh() async {
        await loadPedidos()
    }
}
