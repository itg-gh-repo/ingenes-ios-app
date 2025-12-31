// PedidosView.swift
// TAG2
//
// Pedidos list with modern card-based layout

import SwiftUI

struct PedidosView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PedidosViewModel()
    @State private var selectedPedido: Pedido?

    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            headerSection

            // Search and filter bar
            searchAndFilterBar

            // Active filters
            if viewModel.hasActiveFilters {
                activeFiltersSection
            }

            // Error message if any
            if let errorMessage = viewModel.errorMessage {
                errorBanner(message: errorMessage)
            }

            // Content
            if viewModel.isLoading && viewModel.pedidos.isEmpty {
                loadingView
            } else if viewModel.filteredPedidos.isEmpty {
                emptyState
            } else {
                pedidosList
            }
        }
        .background(AppTheme.backgroundSecondary)
        .navigationTitle("Pedidos")
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
                        // TODO: Sort by Date
                    } label: {
                        Label("Ordenar por Fecha", systemImage: "calendar")
                    }

                    Button {
                        // TODO: Sort by Total
                    } label: {
                        Label("Ordenar por Total", systemImage: "dollarsign.circle")
                    }

                    Button {
                        // TODO: Sort by Status
                    } label: {
                        Label("Ordenar por Estado", systemImage: "flag")
                    }

                    Divider()

                    Button {
                        // TODO: Export
                    } label: {
                        Label("Exportar", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(item: $selectedPedido) { pedido in
            PedidoDetailSheet(pedido: pedido)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showFilters) {
            FilterSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task {
            // Set company ID from current user and load pedidos
            if let companyId = appState.currentUser?.companyId {
                viewModel.setCompanyId(companyId)
            }
            await viewModel.loadPedidos()
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
        VStack(spacing: AppTheme.spacingSM) {
            // Stats cards - First row
            HStack(spacing: AppTheme.spacingSM) {
                PedidoStatCard(
                    title: "Pendientes",
                    value: "\(viewModel.pendingCount)",
                    icon: "clock.fill",
                    color: .orange
                )

                PedidoStatCard(
                    title: "En Proceso",
                    value: "\(viewModel.inProgressCount)",
                    icon: "gearshape.fill",
                    color: .blue
                )

                PedidoStatCard(
                    title: "Entregados",
                    value: "\(viewModel.completedCount)",
                    icon: "checkmark.seal.fill",
                    color: .green
                )
            }

            // Total amount card
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total en Pedidos")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    Text(viewModel.totalAmountFormatted)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.primaryGreen)
                }

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 28))
                    .foregroundColor(AppTheme.primaryGreen.opacity(0.3))
            }
            .padding(AppTheme.spacingSM)
            .background(AppTheme.primaryGreen.opacity(0.1))
            .cornerRadius(AppTheme.radiusMD)
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.vertical, AppTheme.spacingSM)
        .background(AppTheme.backgroundPrimary)
    }

    // MARK: - Search and Filter Bar

    private var searchAndFilterBar: some View {
        HStack(spacing: AppTheme.spacingSM) {
            // Search field
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textMuted)
                    .font(.system(size: 16))

                TextField("Buscar pedidos...", text: $viewModel.searchText)
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

            // Filter button
            Button {
                viewModel.showFilters = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.hasActiveFilters ? .white : AppTheme.primaryGreen)
                        .frame(width: 44, height: 44)
                        .background(viewModel.hasActiveFilters ? AppTheme.primaryGreen : AppTheme.backgroundPrimary)
                        .cornerRadius(AppTheme.radiusMD)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                                .stroke(viewModel.hasActiveFilters ? Color.clear : AppTheme.textMuted.opacity(0.2), lineWidth: 1)
                        )

                    if viewModel.hasActiveFilters {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .offset(x: 4, y: -4)
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.vertical, AppTheme.spacingSM)
    }

    // MARK: - Active Filters Section

    private var activeFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                if let status = viewModel.selectedStatus {
                    FilterChip(
                        label: status.rawValue,
                        color: status.color
                    ) {
                        withAnimation {
                            viewModel.selectedStatus = nil
                        }
                    }
                }

                if let proveedor = viewModel.selectedProveedor {
                    FilterChip(
                        label: proveedor,
                        color: .purple
                    ) {
                        withAnimation {
                            viewModel.selectedProveedor = nil
                        }
                    }
                }

                Button {
                    withAnimation {
                        viewModel.clearFilters()
                    }
                } label: {
                    Text("Limpiar todo")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.errorColor)
                }
            }
            .padding(.horizontal, AppTheme.spacingMD)
        }
        .padding(.bottom, AppTheme.spacingSM)
    }

    // MARK: - Pedidos List

    private var pedidosList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacingSM) {
                ForEach(viewModel.filteredPedidos) { pedido in
                    PedidoCard(pedido: pedido)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPedido = pedido
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
            Text("Cargando pedidos...")
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

                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.primaryGreen)
            }

            VStack(spacing: AppTheme.spacingSM) {
                Text("No se encontraron pedidos")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                if !viewModel.searchText.isEmpty || viewModel.hasActiveFilters {
                    Text("Intenta ajustar los filtros o términos de búsqueda")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        viewModel.searchText = ""
                        viewModel.clearFilters()
                    } label: {
                        Text("Limpiar filtros")
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

// MARK: - Pedido Stat Card

struct PedidoStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.spacingXS) {
            HStack(spacing: AppTheme.spacingXS) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingSM)
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.radiusMD)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(AppTheme.caption)
                .foregroundColor(color)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(color.opacity(0.7))
            }
        }
        .padding(.horizontal, AppTheme.spacingSM)
        .padding(.vertical, AppTheme.spacingXS)
        .background(color.opacity(0.15))
        .cornerRadius(AppTheme.radiusFull)
    }
}

// MARK: - Pedido Card

struct PedidoCard: View {
    let pedido: Pedido

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            // Header row
            HStack(alignment: .top) {
                // ID Badge
                Text(pedido.id)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.spacingSM)
                    .padding(.vertical, AppTheme.spacingXS)
                    .background(AppTheme.primaryGreen)
                    .cornerRadius(AppTheme.radiusSM)

                // Tipo Pedido badge
                if !pedido.tipoPedido.isEmpty {
                    Text(pedido.tipoPedido)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.purple)
                        .padding(.horizontal, AppTheme.spacingXS)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(AppTheme.radiusSM)
                }

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Image(systemName: pedido.statusIcon)
                        .font(.system(size: 10))

                    Text(pedido.statusText)
                        .font(AppTheme.caption2)
                }
                .foregroundColor(pedido.statusColor)
                .padding(.horizontal, AppTheme.spacingSM)
                .padding(.vertical, AppTheme.spacingXS)
                .background(pedido.statusColor.opacity(0.15))
                .cornerRadius(AppTheme.radiusFull)
            }

            // User and Provider row
            HStack(spacing: AppTheme.spacingMD) {
                // User
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)

                    Text(pedido.usuario)
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                if !pedido.proveedor.isEmpty {
                    // Divider
                    Circle()
                        .fill(AppTheme.textMuted)
                        .frame(width: 3, height: 3)

                    // Provider
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)

                        Text(pedido.proveedor)
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            // Project link
            if !pedido.proyecto.isEmpty {
                HStack(spacing: AppTheme.spacingSM) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primaryGreen)

                    Text(pedido.proyecto)
                        .font(AppTheme.callout)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                }
            }

            // Concepto
            if !pedido.concepto.isEmpty {
                Text(pedido.concepto)
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }

            // Footer
            HStack {
                // Date
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(pedido.fechaFormatted)
                        .font(AppTheme.caption2)
                }
                .foregroundColor(AppTheme.textMuted)

                Spacer()

                // Total
                Text(pedido.totalFormatted)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.primaryGreen)
            }
        }
        .padding(AppTheme.spacingMD)
        .background(AppTheme.backgroundPrimary)
        .cornerRadius(AppTheme.radiusLG)
        .shadow(color: AppTheme.shadowLight, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @ObservedObject var viewModel: PedidosViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Status Section - Shows only statuses that exist in the data
                Section("Estado") {
                    ForEach(viewModel.uniqueStatuses, id: \.self) { status in
                        Button {
                            if viewModel.selectedStatus == status {
                                viewModel.selectedStatus = nil
                            } else {
                                viewModel.selectedStatus = status
                            }
                        } label: {
                            HStack {
                                HStack(spacing: AppTheme.spacingSM) {
                                    Image(systemName: status.icon)
                                        .foregroundColor(status.color)
                                        .frame(width: 24)

                                    Text(status.displayName)
                                        .foregroundColor(AppTheme.textPrimary)
                                }

                                Spacer()

                                if viewModel.selectedStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(status.color)
                                }
                            }
                        }
                    }
                }

                // Proveedor Section - Shows only proveedores that exist in the data
                if !viewModel.uniqueProveedores.isEmpty {
                    Section("Proveedor") {
                        ForEach(viewModel.uniqueProveedores, id: \.self) { proveedor in
                            Button {
                                if viewModel.selectedProveedor == proveedor {
                                    viewModel.selectedProveedor = nil
                                } else {
                                    viewModel.selectedProveedor = proveedor
                                }
                            } label: {
                                HStack {
                                    Text(proveedor)
                                        .foregroundColor(AppTheme.textPrimary)

                                    Spacer()

                                    if viewModel.selectedProveedor == proveedor {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppTheme.primaryGreen)
                                    }
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
                    .foregroundColor(AppTheme.errorColor)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aplicar") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }
}

// MARK: - Pedido Detail Sheet

struct PedidoDetailSheet: View {
    let pedido: Pedido
    @Environment(\.dismiss) var dismiss
    @State private var showCotizacion = false
    @State private var showFacturaPDF = false
    @State private var showFacturaXML = false
    @State private var showComprobacion = false

    // Check if any documents are available
    private var hasAnyDocument: Bool {
        !pedido.cotizacionURL.isEmpty ||
        !pedido.facturaPDFURL.isEmpty ||
        !pedido.facturaXMLURL.isEmpty ||
        !pedido.comprobacionURL.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                    // Header with ID and Status
                    HStack {
                        Text(pedido.id)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.spacingMD)
                            .padding(.vertical, AppTheme.spacingSM)
                            .background(AppTheme.primaryGreen)
                            .cornerRadius(AppTheme.radiusMD)

                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: pedido.statusIcon)
                            Text(pedido.statusText)
                        }
                        .font(AppTheme.callout)
                        .foregroundColor(pedido.statusColor)
                        .padding(.horizontal, AppTheme.spacingSM)
                        .padding(.vertical, AppTheme.spacingXS)
                        .background(pedido.statusColor.opacity(0.15))
                        .cornerRadius(AppTheme.radiusFull)
                    }

                    // Total Amount
                    VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                        Text("TOTAL")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textMuted)

                        Text(pedido.totalFormatted)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.spacingMD)
                    .background(AppTheme.primaryGreen.opacity(0.1))
                    .cornerRadius(AppTheme.radiusMD)

                    // User Info
                    PedidoDetailSection(title: "Solicitante") {
                        HStack(spacing: AppTheme.spacingSM) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primaryGreen.opacity(0.1))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "person.fill")
                                    .foregroundColor(AppTheme.primaryGreen)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(pedido.usuario)
                                    .font(AppTheme.headline)
                                    .foregroundColor(AppTheme.textPrimary)

                                Text(pedido.fecha)
                                    .font(AppTheme.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }

                    // Proveedor
                    if !pedido.proveedor.isEmpty {
                        PedidoDetailSection(title: "Proveedor") {
                            HStack(spacing: AppTheme.spacingSM) {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(0.1))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "building.2.fill")
                                        .foregroundColor(.purple)
                                }

                                Text(pedido.proveedor)
                                    .font(AppTheme.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                    }

                    // Proyecto
                    if !pedido.proyecto.isEmpty {
                        PedidoDetailSection(title: "Proyecto") {
                            HStack(spacing: AppTheme.spacingSM) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pedido.proyecto)
                                        .font(AppTheme.headline)
                                        .foregroundColor(AppTheme.textPrimary)

                                    if !pedido.proyectoDescripcion.isEmpty {
                                        Text(pedido.proyectoDescripcion)
                                            .font(AppTheme.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }

                                    if !pedido.proyectoUbicacion.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "mappin")
                                                .font(.system(size: 10))
                                            Text(pedido.proyectoUbicacion)
                                        }
                                        .font(AppTheme.caption)
                                        .foregroundColor(AppTheme.primaryGreen)
                                    }
                                }
                            }
                        }
                    }

                    // Concepto
                    if !pedido.concepto.isEmpty {
                        PedidoDetailSection(title: "Concepto") {
                            Text(pedido.concepto)
                                .font(AppTheme.body)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }

                    // Payment Info
                    if pedido.pagado > 0 || pedido.adeudo > 0 {
                        PedidoDetailSection(title: "Información de Pago") {
                            VStack(spacing: AppTheme.spacingSM) {
                                HStack {
                                    Text("Pagado")
                                        .font(AppTheme.body)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Spacer()
                                    Text(pedido.pagadoFormatted)
                                        .font(AppTheme.headline)
                                        .foregroundColor(AppTheme.successColor)
                                }

                                HStack {
                                    Text("Adeudo")
                                        .font(AppTheme.body)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Spacer()
                                    Text(pedido.adeudoFormatted)
                                        .font(AppTheme.headline)
                                        .foregroundColor(pedido.adeudo > 0 ? AppTheme.errorColor : AppTheme.textPrimary)
                                }
                            }
                            .padding(AppTheme.spacingSM)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.radiusMD)
                        }
                    }

                    // Additional Details
                    VStack(spacing: AppTheme.spacingSM) {
                        if !pedido.tipoPedido.isEmpty {
                            DetailRow(label: "Tipo", value: pedido.tipoPedido)
                        }
                        if !pedido.clase.isEmpty {
                            DetailRow(label: "Clase", value: pedido.clase)
                        }
                        if !pedido.condicionesPago.isEmpty {
                            DetailRow(label: "Condiciones", value: pedido.condicionesPago)
                        }
                        if !pedido.moneda.isEmpty {
                            DetailRow(label: "Moneda", value: pedido.moneda)
                        }
                        if !pedido.observaciones.isEmpty {
                            DetailRow(label: "Observaciones", value: pedido.observaciones)
                        }
                    }
                    .padding(AppTheme.spacingSM)
                    .background(AppTheme.backgroundSecondary)
                    .cornerRadius(AppTheme.radiusMD)

                    // Documents Section
                    if hasAnyDocument {
                        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                            // Section Header
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundColor(AppTheme.primaryGreen)
                                Text("Documentos")
                                    .font(AppTheme.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .padding(.bottom, AppTheme.spacingXS)

                            // Documents Grid - 2x2
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: AppTheme.spacingSM),
                                GridItem(.flexible(), spacing: AppTheme.spacingSM)
                            ], spacing: AppTheme.spacingSM) {
                                // Cotización
                                DocumentButton(
                                    title: "Cotización",
                                    icon: "doc.text.fill",
                                    color: .blue,
                                    isAvailable: !pedido.cotizacionURL.isEmpty
                                ) {
                                    showCotizacion = true
                                }

                                // Factura PDF
                                DocumentButton(
                                    title: "Factura PDF",
                                    icon: "doc.richtext.fill",
                                    color: .purple,
                                    isAvailable: !pedido.facturaPDFURL.isEmpty
                                ) {
                                    showFacturaPDF = true
                                }

                                // Factura XML
                                DocumentButton(
                                    title: "Factura XML",
                                    icon: "chevron.left.forwardslash.chevron.right",
                                    color: .orange,
                                    isAvailable: !pedido.facturaXMLURL.isEmpty
                                ) {
                                    showFacturaXML = true
                                }

                                // Comprobación
                                DocumentButton(
                                    title: "Comprobación",
                                    icon: "checkmark.seal.fill",
                                    color: .teal,
                                    isAvailable: !pedido.comprobacionURL.isEmpty
                                ) {
                                    showComprobacion = true
                                }
                            }
                        }
                        .padding(AppTheme.spacingMD)
                        .background(AppTheme.backgroundSecondary)
                        .cornerRadius(AppTheme.radiusMD)
                    }

                    // Action Buttons
                    VStack(spacing: AppTheme.spacingSM) {
                        HStack(spacing: AppTheme.spacingSM) {
                            Button {
                                // TODO: Approve
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Aprobar")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [AppTheme.successColor, AppTheme.successColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.radiusMD)
                                .shadow(color: AppTheme.successColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            }

                            Button {
                                // TODO: Reject
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Rechazar")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.errorColor.opacity(0.15))
                                .foregroundColor(AppTheme.errorColor)
                                .cornerRadius(AppTheme.radiusMD)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                                        .stroke(AppTheme.errorColor.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .font(.system(size: 15, weight: .semibold))

                        Button {
                            dismiss()
                        } label: {
                            Text("Cerrar")
                                .font(AppTheme.callout)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.top, AppTheme.spacingSM)
                    }
                    .padding(.top, AppTheme.spacingMD)
                }
                .padding(AppTheme.spacingMD)
            }
            .navigationTitle("Detalle del Pedido")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCotizacion) {
                if let url = URL(string: pedido.cotizacionURL), !pedido.cotizacionURL.isEmpty {
                    PDFViewerSheet(url: url, title: "Cotización - \(pedido.id)")
                } else {
                    DocumentErrorSheet(title: "Cotización", message: "El documento no está disponible")
                }
            }
            .sheet(isPresented: $showFacturaPDF) {
                if let url = URL(string: pedido.facturaPDFURL), !pedido.facturaPDFURL.isEmpty {
                    PDFViewerSheet(url: url, title: "Factura PDF - \(pedido.id)")
                } else {
                    DocumentErrorSheet(title: "Factura PDF", message: "El documento no está disponible")
                }
            }
            .sheet(isPresented: $showFacturaXML) {
                if let url = URL(string: pedido.facturaXMLURL), !pedido.facturaXMLURL.isEmpty {
                    XMLViewerSheet(url: url, title: "Factura XML - \(pedido.id)")
                } else {
                    DocumentErrorSheet(title: "Factura XML", message: "El documento no está disponible")
                }
            }
            .sheet(isPresented: $showComprobacion) {
                if let url = URL(string: pedido.comprobacionURL), !pedido.comprobacionURL.isEmpty {
                    PDFViewerSheet(url: url, title: "Comprobación - \(pedido.id)")
                } else {
                    DocumentErrorSheet(title: "Comprobación", message: "El documento no está disponible")
                }
            }
        }
    }
}

// MARK: - Document Button Component

struct DocumentButton: View {
    let title: String
    let icon: String
    let color: Color
    let isAvailable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isAvailable ? color.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isAvailable ? color : .gray.opacity(0.5))
                }

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isAvailable ? AppTheme.textPrimary : AppTheme.textMuted)
                    .lineLimit(1)

                // Availability indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(isAvailable ? AppTheme.successColor : Color.gray.opacity(0.4))
                        .frame(width: 6, height: 6)
                    Text(isAvailable ? "Disponible" : "No disponible")
                        .font(.system(size: 10))
                        .foregroundColor(isAvailable ? AppTheme.successColor : AppTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .fill(isAvailable ? color.opacity(0.05) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .stroke(isAvailable ? color.opacity(0.2) : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .disabled(!isAvailable)
        .buttonStyle(ScaleButtonStyle())
    }
}

// Custom button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Document Error Sheet

struct DocumentErrorSheet: View {
    let title: String
    let message: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.spacingLG) {
                Spacer()

                Image(systemName: "doc.questionmark.fill")
                    .font(.system(size: 64))
                    .foregroundColor(AppTheme.textMuted)

                Text(message)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(AppTheme.spacingLG)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
}

// MARK: - XML Viewer Sheet

struct XMLViewerSheet: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var xmlContent: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                if let errorMessage = errorMessage {
                    VStack(spacing: AppTheme.spacingMD) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Error al cargar el documento")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        Text(errorMessage)
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            isLoading = true
                            self.errorMessage = nil
                            loadXML()
                        } label: {
                            Text("Reintentar")
                                .font(AppTheme.callout)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(AppTheme.spacingLG)
                } else if isLoading {
                    VStack(spacing: AppTheme.spacingMD) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Cargando documento...")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        Text(xmlContent)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding()
                    }
                    .background(AppTheme.backgroundSecondary)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !xmlContent.isEmpty {
                        ShareLink(item: xmlContent) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .onAppear {
            loadXML()
        }
    }

    private func loadXML() {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let content = String(data: data, encoding: .utf8) {
                    await MainActor.run {
                        xmlContent = content
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "No se pudo leer el contenido del archivo"
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - PDF Viewer Sheet

struct PDFViewerSheet: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                if let errorMessage = errorMessage {
                    VStack(spacing: AppTheme.spacingMD) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Error al cargar el documento")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        Text(errorMessage)
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            isLoading = true
                            self.errorMessage = nil
                        } label: {
                            Text("Reintentar")
                                .font(AppTheme.callout)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(AppTheme.spacingLG)
                } else {
                    PDFKitView(url: url, isLoading: $isLoading, errorMessage: $errorMessage)

                    if isLoading {
                        VStack(spacing: AppTheme.spacingMD) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Cargando documento...")
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.backgroundPrimary.opacity(0.9))
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                }
            }
        }
    }
}

// MARK: - PDFKit View

import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Only load if we don't have a document yet
        guard pdfView.document == nil else { return }

        // Load PDF asynchronously
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    await MainActor.run {
                        errorMessage = "El servidor no pudo proporcionar el documento."
                        isLoading = false
                    }
                    return
                }

                if let document = PDFDocument(data: data) {
                    await MainActor.run {
                        pdfView.document = document
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "No se pudo procesar el documento PDF."
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error de conexión: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Pedido Detail Section

struct PedidoDetailSection<Content: View>: View {
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

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textMuted)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(AppTheme.body)
                .foregroundColor(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PedidosView()
    }
}
