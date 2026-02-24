// NotasMedicasView.swift
// Ingenes
//
// Medical notes list and detail view

import SwiftUI

struct NotasMedicasView: View {
    @StateObject private var viewModel = NotasMedicasViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedNota: NotaMedica?

    var body: some View {
        VStack(spacing: 0) {
            // Stats Header
            statsHeader

            // Search + Filter
            searchAndFilter

            // Notes List
            if viewModel.isLoading {
                Spacer()
                ProgressView("Cargando notas...")
                Spacer()
            } else if viewModel.filteredNotas.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacingSM) {
                        ForEach(viewModel.filteredNotas) { nota in
                            NotaMedicaCard(nota: nota)
                                .onTapGesture {
                                    selectedNota = nota
                                }
                        }
                    }
                    .padding(.horizontal, AppTheme.spacingMD)
                    .padding(.vertical, AppTheme.spacingSM)
                }
            }
        }
        .navigationTitle("Notas Médicas")
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
        }
        .sheet(item: $selectedNota) { nota in
            NotaMedicaDetailSheet(nota: nota)
        }
        .task {
            await viewModel.loadNotas()
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 12) {
            StatCard(title: "Total", value: "\(viewModel.totalCount)", color: AppTheme.primaryGreen)
            StatCard(title: "Pendientes", value: "\(viewModel.pendienteCount)", color: .orange)
            StatCard(title: "Completadas", value: "\(viewModel.completadaCount)", color: Color(hex: "388E3C"))
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
                TextField("Buscar por NHC, paciente o doctor...", text: $viewModel.searchText)
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

            // Type filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(title: "Todas", isSelected: viewModel.selectedTipoNota == nil) {
                        viewModel.selectedTipoNota = nil
                    }

                    ForEach(TipoNota.allCases) { tipo in
                        FilterPill(
                            title: tipo.shortName,
                            isSelected: viewModel.selectedTipoNota == tipo,
                            color: tipo.color
                        ) {
                            viewModel.selectedTipoNota = viewModel.selectedTipoNota == tipo ? nil : tipo
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.bottom, AppTheme.spacingSM)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textMuted)

            Text("No se encontraron notas")
                .font(AppTheme.callout)
                .foregroundColor(AppTheme.textSecondary)

            Text("Intenta con otros filtros de búsqueda")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textMuted)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = AppTheme.primaryGreen

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(16)
        }
    }
}

// MARK: - Nota Médica Card

struct NotaMedicaCard: View {
    let nota: NotaMedica

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            // Top row: Type badge + date
            HStack {
                // Type badge
                HStack(spacing: 4) {
                    Image(systemName: nota.tipoNota.icon)
                        .font(.system(size: 10))
                    Text(nota.tipoNota.shortName)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(nota.tipoNota.color)
                .cornerRadius(12)

                Spacer()

                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: nota.estatus.icon)
                        .font(.system(size: 9))
                    Text(nota.estatus.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(nota.estatus.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(nota.estatus.color.opacity(0.12))
                .cornerRadius(8)
            }

            // Patient info
            HStack(spacing: AppTheme.spacingSM) {
                Circle()
                    .fill(nota.tipoNota.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(nota.paciente.iniciales)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(nota.tipoNota.color)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(nota.paciente.nombreCompleto)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text(nota.paciente.nhc)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(nota.fechaCorta)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    Text(nota.modalidad)
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted)
                }
            }

            // Doctor
            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textMuted)
                Text(nota.doctor)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                Text(nota.subtipo)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(AppTheme.spacingMD)
        .cardStyle()
    }
}

// MARK: - Detail Sheet

struct NotaMedicaDetailSheet: View {
    let nota: NotaMedica
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                    // Patient header
                    patientHeader

                    // Note type and status
                    noteTypeSection

                    // Vitals grid
                    if let vitals = nota.signosVitales {
                        vitalsSection(vitals)
                    }

                    // Note text
                    if !nota.textoNota.isEmpty {
                        noteTextSection
                    }

                    // Meta info
                    metaInfoSection
                }
                .padding(AppTheme.spacingMD)
            }
            .navigationTitle("Detalle de Nota")
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

    private var patientHeader: some View {
        HStack(spacing: AppTheme.spacingMD) {
            Circle()
                .fill(nota.tipoNota.color.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(nota.paciente.iniciales)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(nota.tipoNota.color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(nota.paciente.nombreCompleto)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                HStack(spacing: 12) {
                    Label(nota.paciente.nhc, systemImage: "number")
                    Label(nota.paciente.edadTexto, systemImage: "calendar")
                }
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)

                Text(nota.doctor)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(nota.tipoNota.color)
            }
        }
        .padding(AppTheme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var noteTypeSection: some View {
        HStack {
            // Type badge
            HStack(spacing: 6) {
                Image(systemName: nota.tipoNota.icon)
                    .font(.system(size: 14))
                Text(nota.tipoNota.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(nota.tipoNota.color)
            .cornerRadius(12)

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                Image(systemName: nota.estatus.icon)
                    .font(.system(size: 12))
                Text(nota.estatus.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(nota.estatus.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(nota.estatus.color.opacity(0.12))
            .cornerRadius(10)
        }
    }

    private func vitalsSection(_ vitals: SignosVitales) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("Signos Vitales")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let peso = vitals.peso {
                    VitalItem(label: "Peso", value: String(format: "%.1f kg", peso), icon: "scalemass.fill")
                }
                if let estatura = vitals.estatura {
                    VitalItem(label: "Estatura", value: String(format: "%.0f cm", estatura), icon: "ruler.fill")
                }
                if let imc = vitals.imc {
                    VitalItem(label: "IMC", value: String(format: "%.1f", imc), icon: "figure.stand")
                }
                if let pa = vitals.presionArterial {
                    VitalItem(label: "Presión Art.", value: "\(pa) mmHg", icon: "heart.fill")
                }
                if let fc = vitals.frecuenciaCardiaca {
                    VitalItem(label: "Frec. Cardíaca", value: "\(fc) bpm", icon: "waveform.path.ecg")
                }
                if let fr = vitals.frecuenciaRespiratoria {
                    VitalItem(label: "Frec. Resp.", value: "\(fr) rpm", icon: "lungs.fill")
                }
                if let spo2 = vitals.saturacionO2 {
                    VitalItem(label: "SpO2", value: "\(spo2)%", icon: "drop.fill")
                }
                if let temp = vitals.temperatura {
                    VitalItem(label: "Temperatura", value: String(format: "%.1f °C", temp), icon: "thermometer.medium")
                }
            }
        }
        .padding(AppTheme.spacingMD)
        .cardStyle()
    }

    private var noteTextSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("Nota")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            Text(nota.textoNota)
                .font(AppTheme.body)
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var metaInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Información")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            DetailRow(label: "Fecha", value: nota.fechaFormateada)
            DetailRow(label: "Modalidad", value: nota.modalidad)
            DetailRow(label: "Subtipo", value: nota.subtipo)
            DetailRow(label: "Área", value: nota.area)
            DetailRow(label: "Doctor", value: nota.doctor)
            if let enfermera = nota.enfermera {
                DetailRow(label: "Enfermera", value: enfermera)
            }
        }
        .padding(AppTheme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Vital Item

struct VitalItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "4A90D9"))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(8)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotasMedicasView()
    }
}
