// TratamientosView.swift
// Ingenes
//
// Treatments list with embryo timeline detail

import SwiftUI

struct TratamientosView: View {
    @StateObject private var viewModel = TratamientosViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedTratamiento: Tratamiento?

    var body: some View {
        VStack(spacing: 0) {
            // Stats Header
            statsHeader

            // Search + Filters
            searchAndFilter

            // Treatment List
            if viewModel.isLoading {
                Spacer()
                ProgressView("Cargando tratamientos...")
                Spacer()
            } else if viewModel.filteredTratamientos.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacingSM) {
                        ForEach(viewModel.filteredTratamientos) { tratamiento in
                            TratamientoCard(tratamiento: tratamiento)
                                .onTapGesture {
                                    selectedTratamiento = tratamiento
                                }
                        }
                    }
                    .padding(.horizontal, AppTheme.spacingMD)
                    .padding(.vertical, AppTheme.spacingSM)
                }
            }
        }
        .navigationTitle("Tratamientos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Dashboard")
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showFilters = true
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
        .sheet(item: $selectedTratamiento) { tratamiento in
            TratamientoDetailSheet(tratamiento: tratamiento)
        }
        .sheet(isPresented: $viewModel.showFilters) {
            TratamientoFilterSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .task {
            await viewModel.loadTratamientos()
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 12) {
            StatCard(title: "En Curso", value: "\(viewModel.enCursoCount)", color: Color(hex: "4A90D9"))
            StatCard(title: "Completados", value: "\(viewModel.completadoCount)", color: AppTheme.primaryGreen)
            StatCard(title: "Positivos", value: "\(viewModel.positivoCount)", color: Color(hex: "388E3C"))
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.vertical, AppTheme.spacingSM)
    }

    // MARK: - Search and Filter

    private var searchAndFilter: some View {
        VStack(spacing: AppTheme.spacingSM) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textMuted)
                TextField("Buscar por NHC, paciente o tratamiento...", text: $viewModel.searchText)
                    .font(AppTheme.subheadline)

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }
            .padding(AppTheme.spacingSM)
            .background(AppTheme.backgroundSecondary)
            .cornerRadius(AppTheme.radiusMD)

            // Active filter chips
            if viewModel.hasActiveFilters {
                HStack(spacing: 8) {
                    if let tipo = viewModel.selectedTipo {
                        ActiveFilterChip(label: tipo.shortName, color: tipo.color) {
                            viewModel.selectedTipo = nil
                        }
                    }
                    if let resultado = viewModel.selectedResultado {
                        ActiveFilterChip(label: resultado.rawValue, color: resultado.color) {
                            viewModel.selectedResultado = nil
                        }
                    }

                    Spacer()

                    Button("Limpiar") {
                        viewModel.clearFilters()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                }
            }
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.bottom, AppTheme.spacingSM)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textMuted)

            Text("No se encontraron tratamientos")
                .font(AppTheme.callout)
                .foregroundColor(AppTheme.textSecondary)

            Text("Intenta con otros filtros de búsqueda")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textMuted)
        }
    }
}

// MARK: - Active Filter Chip

struct ActiveFilterChip: View {
    let label: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .cornerRadius(12)
    }
}

// MARK: - Tratamiento Card

struct TratamientoCard: View {
    let tratamiento: Tratamiento

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            // Top row: Treatment ID + Result
            HStack {
                Text(tratamiento.nIni)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)

                Spacer()

                // Result badge
                HStack(spacing: 4) {
                    Image(systemName: tratamiento.resultado.icon)
                        .font(.system(size: 9))
                    Text(tratamiento.resultado.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(tratamiento.resultado.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(tratamiento.resultado.color.opacity(0.12))
                .cornerRadius(8)
            }

            // Patient info
            HStack(spacing: AppTheme.spacingSM) {
                Circle()
                    .fill(tratamiento.tipoTratamiento.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(tratamiento.paciente.iniciales)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(tratamiento.tipoTratamiento.color)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(tratamiento.paciente.nombreCompleto)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)

                    if let pareja = tratamiento.paciente.parejaNombre {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9))
                            Text(pareja)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(AppTheme.textMuted)
                    }
                }

                Spacer()

                // Treatment type badge
                Text(tratamiento.tipoTratamiento.shortName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tratamiento.tipoTratamiento.color)
                    .cornerRadius(8)
            }

            // Bottom row: Cycle type + Transfer date
            HStack {
                Label(tratamiento.tipoCiclo, systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)

                if tratamiento.seguro {
                    HStack(spacing: 2) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 9))
                        Text("Seguro")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color(hex: "388E3C"))
                }

                Spacer()

                if let fecha = tratamiento.fechaTransferFormateada {
                    Label(fecha, systemImage: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
        }
        .padding(AppTheme.spacingMD)
        .cardStyle()
    }
}

// MARK: - Filter Sheet

struct TratamientoFilterSheet: View {
    @ObservedObject var viewModel: TratamientosViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Tipo de Tratamiento") {
                    ForEach(TipoTratamiento.allCases) { tipo in
                        Button {
                            viewModel.selectedTipo = viewModel.selectedTipo == tipo ? nil : tipo
                        } label: {
                            HStack {
                                Circle()
                                    .fill(tipo.color)
                                    .frame(width: 10, height: 10)
                                Text(tipo.rawValue)
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                if viewModel.selectedTipo == tipo {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.primaryGreen)
                                }
                            }
                        }
                    }
                }

                Section("Resultado") {
                    ForEach(ResultadoTratamiento.allCases, id: \.rawValue) { resultado in
                        Button {
                            viewModel.selectedResultado = viewModel.selectedResultado == resultado ? nil : resultado
                        } label: {
                            HStack {
                                Image(systemName: resultado.icon)
                                    .foregroundColor(resultado.color)
                                Text(resultado.rawValue)
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                if viewModel.selectedResultado == resultado {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.primaryGreen)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Limpiar") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }
}

// MARK: - Tratamiento Detail Sheet

struct TratamientoDetailSheet: View {
    let tratamiento: Tratamiento
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                    // Patient info card
                    patientCard

                    // Treatment details card
                    treatmentDetailsCard

                    // Embryo timeline
                    if !tratamiento.embriones.isEmpty {
                        embryoTimelineCard
                    }
                }
                .padding(AppTheme.spacingMD)
            }
            .navigationTitle("Detalle de Tratamiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }

    // MARK: - Patient Card

    private var patientCard: some View {
        HStack(spacing: AppTheme.spacingMD) {
            Circle()
                .fill(tratamiento.tipoTratamiento.color.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(tratamiento.paciente.iniciales)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(tratamiento.tipoTratamiento.color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(tratamiento.paciente.nombreCompleto)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                HStack(spacing: 12) {
                    Label(tratamiento.paciente.nhc, systemImage: "number")
                    Label(tratamiento.paciente.edadTexto, systemImage: "calendar")
                }
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)

                if let pareja = tratamiento.paciente.parejaNombre {
                    Label(pareja, systemImage: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
        }
        .padding(AppTheme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Treatment Details

    private var treatmentDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                Text("Detalles del Tratamiento")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                // Result badge
                HStack(spacing: 4) {
                    Image(systemName: tratamiento.resultado.icon)
                    Text(tratamiento.resultado.rawValue)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(tratamiento.resultado.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(tratamiento.resultado.color.opacity(0.12))
                .cornerRadius(10)
            }

            Divider()

            DetailRow(label: "N° INI", value: tratamiento.nIni)
            DetailRow(label: "Tratamiento", value: tratamiento.nombreTratamiento)
            DetailRow(label: "Tipo", value: tratamiento.tipoTratamiento.rawValue)
            DetailRow(label: "Ciclo", value: tratamiento.tipoCiclo)
            DetailRow(label: "Etiología", value: tratamiento.etiologiaFemenina)
            DetailRow(label: "Seguro", value: tratamiento.seguro ? "Sí" : "No")

            if let fecha = tratamiento.fechaTransferFormateada {
                DetailRow(label: "Transfer", value: fecha)
            }
        }
        .padding(AppTheme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Embryo Timeline

    private var embryoTimelineCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                Image(systemName: "circle.hexagonpath.fill")
                    .foregroundColor(tratamiento.tipoTratamiento.color)
                Text("Timeline de Embriones")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Text("\(tratamiento.embrioneViableCount) viables")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "388E3C"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(tratamiento.embriones.enumerated()), id: \.element.id) { index, embryo in
                        VStack(spacing: 6) {
                            // Day label
                            Text(embryo.diaTexto)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)

                            // Circle node
                            ZStack {
                                Circle()
                                    .fill(embryo.estado.color.opacity(0.2))
                                    .frame(width: 48, height: 48)

                                Circle()
                                    .fill(embryo.estado.color)
                                    .frame(width: 36, height: 36)

                                Image(systemName: embryo.estado.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            // Grade label
                            if let grado = embryo.grado {
                                Text(grado)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(embryo.estado.color)
                            }

                            // Status label
                            Text(embryo.estado.rawValue)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                                .lineLimit(1)
                        }
                        .frame(width: 64)

                        // Connector line
                        if index < tratamiento.embriones.count - 1 {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            tratamiento.embriones[index].estado.color,
                                            tratamiento.embriones[index + 1].estado.color
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 20, height: 3)
                                .offset(y: -10)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.spacingSM)
                .padding(.vertical, AppTheme.spacingSM)
            }
        }
        .padding(AppTheme.spacingMD)
        .cardStyle()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TratamientosView()
    }
}
