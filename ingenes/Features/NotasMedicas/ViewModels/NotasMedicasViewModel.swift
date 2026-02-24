// NotasMedicasViewModel.swift
// Ingenes
//
// Business logic for medical notes feature

import Foundation
import SwiftUI
import Combine

@MainActor
class NotasMedicasViewModel: ObservableObject {
    // MARK: - Published State

    @Published var notas: [NotaMedica] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedTipoNota: TipoNota?

    // MARK: - Filtered Data

    var filteredNotas: [NotaMedica] {
        var result = notas

        // Filter by type
        if let tipo = selectedTipoNota {
            result = result.filter { $0.tipoNota == tipo }
        }

        // Filter by search text
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.paciente.nhc.lowercased().contains(query) ||
                $0.paciente.nombreCompleto.lowercased().contains(query) ||
                $0.doctor.lowercased().contains(query)
            }
        }

        // Sort by date (newest first)
        return result.sorted { $0.fecha > $1.fecha }
    }

    // MARK: - Stats

    var totalCount: Int { notas.count }

    var pendienteCount: Int {
        notas.filter { $0.estatus == .pendiente }.count
    }

    var completadaCount: Int {
        notas.filter { $0.estatus == .completada }.count
    }

    // MARK: - Data Loading

    func loadNotas() async {
        isLoading = true
        defer { isLoading = false }

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 300_000_000)

        notas = NotaMedica.mockList
    }
}
