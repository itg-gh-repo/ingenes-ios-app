// ProyectosView.swift
// Ingenes
//
// Proyectos list with modern card-based layout

import SwiftUI

struct ProyectosView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProyectosViewModel()
    @State private var selectedProyecto: Proyecto?
    @Namespace private var animation

    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            headerSection

            // Search bar
            searchBar

            // Error message if any
            if let errorMessage = viewModel.errorMessage {
                errorBanner(message: errorMessage)
            }

            // Content
            if viewModel.isLoading && viewModel.proyectos.isEmpty {
                loadingView
            } else if viewModel.filteredProyectos.isEmpty {
                emptyState
            } else {
                projectsList
            }
        }
        .background(AppTheme.backgroundSecondary)
        .navigationTitle("Proyectos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        // TODO: Sort by ID
                    } label: {
                        Label("Ordenar por ID", systemImage: "number")
                    }

                    Button {
                        // TODO: Sort by Client
                    } label: {
                        Label("Ordenar por Cliente", systemImage: "person")
                    }

                    Button {
                        // TODO: Sort by Date
                    } label: {
                        Label("Ordenar por Fecha", systemImage: "calendar")
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(item: $selectedProyecto) { proyecto in
            ProyectoDetailSheet(proyecto: proyecto)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task {
            // Set company ID from current user and load projects
            if let companyId = appState.currentUser?.companyId {
                viewModel.setCompanyId(companyId)
            }
            await viewModel.loadProyectos()
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Text("Reintentar")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.primaryGreen)
            }
        }
        .padding(AppTheme.spacingSM)
        .background(Color.orange.opacity(0.1))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: AppTheme.spacingMD) {
            // Stats cards
            HStack(spacing: AppTheme.spacingSM) {
                StatCard(
                    title: "Total",
                    value: "\(viewModel.proyectos.count)",
                    icon: "folder.fill",
                    color: .blue
                )

                StatCard(
                    title: "Activos",
                    value: "\(viewModel.activeCount)",
                    icon: "clock.fill",
                    color: .orange
                )

                StatCard(
                    title: "Completados",
                    value: "\(viewModel.completedCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.vertical, AppTheme.spacingSM)
        .background(AppTheme.backgroundPrimary)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppTheme.spacingSM) {
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textMuted)
                    .font(.system(size: 16))

                TextField("Buscar por ID, cliente o descripción...", text: $viewModel.searchText)
                    .font(AppTheme.body)

                if !viewModel.searchText.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textMuted)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacingSM)
            .padding(.vertical, AppTheme.spacingSM)
            .background(AppTheme.backgroundPrimary)
            .cornerRadius(AppTheme.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .stroke(AppTheme.textMuted.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.vertical, AppTheme.spacingSM)
    }

    // MARK: - Projects List

    private var projectsList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacingSM) {
                ForEach(viewModel.filteredProyectos) { proyecto in
                    ProyectoCard(proyecto: proyecto)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedProyecto = proyecto
                            }
                        }
                }
            }
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, AppTheme.spacingSM)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Cargando proyectos...")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacingLG) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.primaryGreen.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.primaryGreen)
            }

            VStack(spacing: AppTheme.spacingSM) {
                Text("No se encontraron proyectos")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                if !viewModel.searchText.isEmpty {
                    Text("Intenta con otros términos de búsqueda")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Text("Limpiar búsqueda")
                            .font(AppTheme.callout)
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                    .padding(.top, AppTheme.spacingSM)
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.spacingXL)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.spacingXS) {
            HStack(spacing: AppTheme.spacingXS) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)

                Text(title)
                    .font(AppTheme.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingSM)
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.radiusMD)
    }
}

// MARK: - Proyecto Card

struct ProyectoCard: View {
    let proyecto: Proyecto

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            // Header row
            HStack(alignment: .top) {
                // ID Badge
                Text(proyecto.id)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.spacingSM)
                    .padding(.vertical, AppTheme.spacingXS)
                    .background(AppTheme.primaryGreen)
                    .cornerRadius(AppTheme.radiusSM)

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(proyecto.statusColor)
                        .frame(width: 8, height: 8)

                    Text(proyecto.statusText)
                        .font(AppTheme.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Client name
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primaryGreen)

                Text(proyecto.cliente)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
            }

            // Description
            Text(proyecto.descripcion)
                .font(AppTheme.callout)
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(2)

            // Footer
            HStack {
                // Date info
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(proyecto.fechaCreacion)
                        .font(AppTheme.caption2)
                }
                .foregroundColor(AppTheme.textMuted)

                Spacer()

                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(AppTheme.spacingMD)
        .background(AppTheme.backgroundPrimary)
        .cornerRadius(AppTheme.radiusLG)
        .shadow(color: AppTheme.shadowLight, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Proyecto Detail Sheet

struct ProyectoDetailSheet: View {
    let proyecto: Proyecto
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                    // ID and Status
                    HStack {
                        Text(proyecto.id)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.spacingMD)
                            .padding(.vertical, AppTheme.spacingSM)
                            .background(AppTheme.primaryGreen)
                            .cornerRadius(AppTheme.radiusMD)

                        // Project Type Badge
                        Text(proyecto.tipoProyecto)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.primaryGreen)
                            .padding(.horizontal, AppTheme.spacingSM)
                            .padding(.vertical, AppTheme.spacingXS)
                            .background(AppTheme.primaryGreen.opacity(0.1))
                            .cornerRadius(AppTheme.radiusSM)

                        Spacer()

                        HStack(spacing: 6) {
                            Circle()
                                .fill(proyecto.statusColor)
                                .frame(width: 10, height: 10)

                            Text(proyecto.statusText)
                                .font(AppTheme.callout)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.horizontal, AppTheme.spacingSM)
                        .padding(.vertical, AppTheme.spacingXS)
                        .background(proyecto.statusColor.opacity(0.1))
                        .cornerRadius(AppTheme.radiusFull)
                    }

                    // Client Info
                    DetailSection(title: "Cliente") {
                        HStack(spacing: AppTheme.spacingSM) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primaryGreen.opacity(0.1))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "building.2.fill")
                                    .foregroundColor(AppTheme.primaryGreen)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(proyecto.cliente)
                                    .font(AppTheme.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .lineLimit(2)
                            }
                        }
                    }

                    // Description
                    DetailSection(title: "Descripción") {
                        Text(proyecto.descripcion)
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    // Location
                    if !proyecto.ubicacion.isEmpty {
                        DetailSection(title: "Ubicación") {
                            HStack(alignment: .top, spacing: AppTheme.spacingSM) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(AppTheme.primaryGreen)
                                    .frame(width: 20)

                                Text(proyecto.ubicacion)
                                    .font(AppTheme.body)
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                    }

                    // Dates
                    DetailSection(title: "Fechas") {
                        VStack(spacing: AppTheme.spacingSM) {
                            DateRow(label: "Registro", date: proyecto.fechaCreacion, icon: "calendar.badge.plus")
                            DateRow(label: "Inicio", date: formatDateString(proyecto.fechaInicio), icon: "play.circle")
                            DateRow(label: "Fin", date: formatDateString(proyecto.fechaFinal), icon: "checkmark.circle")
                        }
                    }

                    // Responsible
                    if !proyecto.responsable.isEmpty {
                        DetailSection(title: "Responsable") {
                            HStack(spacing: AppTheme.spacingSM) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(AppTheme.primaryGreen)
                                    .frame(width: 20)

                                Text(proyecto.responsable)
                                    .font(AppTheme.body)
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                    }

                    // Actions
                    VStack(spacing: AppTheme.spacingSM) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cerrar")
                                .font(AppTheme.callout)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(.top, AppTheme.spacingMD)
                }
                .padding(AppTheme.spacingMD)
            }
            .navigationTitle("Detalle del Proyecto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
        }
    }

    private func formatDateString(_ dateString: String) -> String {
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

// MARK: - Detail Section

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text(title)
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textMuted)
                .textCase(.uppercase)

            content
        }
    }
}

// MARK: - Date Row

struct DateRow: View {
    let label: String
    let date: String
    let icon: String

    var body: some View {
        HStack {
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primaryGreen)
                    .frame(width: 20)

                Text(label)
                    .font(AppTheme.callout)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Text(date)
                .font(AppTheme.callout)
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProyectosView()
            .environmentObject(AppState())
    }
}
