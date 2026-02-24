// TratamientosViewModel.swift
// Ingenes
//
// Business logic for treatments feature

import Foundation
import SwiftUI
import Combine

@MainActor
class TratamientosViewModel: ObservableObject {
    // MARK: - Published State

    @Published var tratamientos: [Tratamiento] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedTipo: TipoTratamiento?
    @Published var selectedResultado: ResultadoTratamiento?
    @Published var showFilters = false

    // MARK: - Filtered Data

    var filteredTratamientos: [Tratamiento] {
        var result = tratamientos

        if let tipo = selectedTipo {
            result = result.filter { $0.tipoTratamiento == tipo }
        }

        if let resultado = selectedResultado {
            result = result.filter { $0.resultado == resultado }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.paciente.nhc.lowercased().contains(query) ||
                $0.paciente.nombreCompleto.lowercased().contains(query) ||
                $0.nIni.lowercased().contains(query) ||
                $0.nombreTratamiento.lowercased().contains(query)
            }
        }

        return result
    }

    // MARK: - Stats

    var enCursoCount: Int {
        tratamientos.filter { $0.resultado == .enCurso }.count
    }

    var completadoCount: Int {
        tratamientos.filter { $0.resultado == .positivo || $0.resultado == .negativo }.count
    }

    var positivoCount: Int {
        tratamientos.filter { $0.resultado == .positivo }.count
    }

    var hasActiveFilters: Bool {
        selectedTipo != nil || selectedResultado != nil
    }

    // MARK: - Data Loading

    func loadTratamientos() async {
        isLoading = true
        defer { isLoading = false }

        try? await Task.sleep(nanoseconds: 300_000_000)

        tratamientos = Tratamiento.mockList
    }

    func clearFilters() {
        selectedTipo = nil
        selectedResultado = nil
    }
}
