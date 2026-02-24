// DashboardView.swift
// Ingenes
//
// Main dashboard screen for fertility clinic

import SwiftUI
import Combine

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: DashboardViewModel

    @State private var showNotasMedicas = false
    @State private var showTratamientos = false
    @State private var showSideMenu = false
    @State private var selectedChartTab: ChartTab = .pacientes

    // MARK: - Chart Tab

    enum ChartTab: String, CaseIterable {
        case pacientes = "Pacientes"
        case tratamientos = "Tratamientos"
    }

    // MARK: - Bar Chart Sizing

    private var barHeightMultiplier: CGFloat {
        let maxCount = viewModel.pacientesData.map { $0.count }.max() ?? 1
        if maxCount == 0 { return 1 }
        return 80 / CGFloat(maxCount)
    }

    init() {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(user: User.mock))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    welcomeHeader
                    tabbedChartsCard
                    quickActionsSection
                    notificationsCard
                }
                .padding(.horizontal, AppTheme.spacingMD)
                .padding(.vertical, AppTheme.spacingMD)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSideMenu = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                }
            }
            .sheet(isPresented: $showSideMenu) {
                SideMenuView { destination in
                    handleMenuNavigation(destination)
                }
            }
            .fullScreenCover(isPresented: $showNotasMedicas) {
                NavigationStack {
                    NotasMedicasView()
                }
            }
            .fullScreenCover(isPresented: $showTratamientos) {
                NavigationStack {
                    TratamientosView()
                }
            }
            .task {
                await viewModel.loadDashboardData()
            }
        }
    }

    // MARK: - Navigation

    private func handleMenuNavigation(_ destination: MenuDestination) {
        switch destination {
        case .dashboard:
            break
        case .notasMedicas:
            showNotasMedicas = true
        case .tratamientos:
            showTratamientos = true
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
            if let user = appState.currentUser {
                Text("\(viewModel.welcomeMessage), \(user.firstName.isEmpty ? user.username : user.firstName)!")
                    .font(AppTheme.title2)
                    .foregroundColor(AppTheme.textPrimary)

                Text(user.userTypeDisplayName)
                    .font(AppTheme.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppTheme.spacingSM)
    }

    // MARK: - Notifications Card

    private var notificationsCard: some View {
        VStack(spacing: AppTheme.spacingSM) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(AppTheme.primaryGreen)

                Text("Notificaciones")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Text("\(viewModel.notifications.count)")
                    .font(AppTheme.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.spacingSM)
                    .padding(.vertical, 2)
                    .background(AppTheme.primaryGreen)
                    .cornerRadius(AppTheme.radiusFull)

                Spacer()

                Button("Ver todas") {
                    // TODO: Navigate to notifications
                }
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.primaryGreen)
            }

            VStack(spacing: AppTheme.spacingXS) {
                ForEach(viewModel.notifications.prefix(3)) { notification in
                    CompactNotificationRow(notification: notification)
                }
            }
        }
        .padding(AppTheme.spacingMD)
        .cardStyle()
    }

    // MARK: - Tabbed Charts Card

    private var currentTabColor: Color {
        selectedChartTab == .pacientes ? AppTheme.primaryGreen : Color.pink
    }

    private var tabbedChartsCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Image(systemName: selectedChartTab == .pacientes ? "chart.bar.fill" : "chart.pie.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(currentTabColor)
                    .animation(.easeInOut(duration: 0.2), value: selectedChartTab)

                Text(selectedChartTab == .pacientes ? "Pacientes Atendidos" : "Tipos de Tratamiento")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                if selectedChartTab == .pacientes {
                    Menu {
                        ForEach(ClinicPeriod.allCases, id: \.self) { period in
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.selectedPeriod = period
                                }
                                Task { await viewModel.refresh() }
                            } label: {
                                HStack {
                                    Text(period.rawValue)
                                    if viewModel.selectedPeriod == period {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .medium))
                            Text(viewModel.selectedPeriod.rawValue)
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(currentTabColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(currentTabColor.opacity(0.12))
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.top, AppTheme.spacingMD)
            .padding(.bottom, AppTheme.spacingSM)

            // Tab Control
            HStack(spacing: 0) {
                ForEach(ChartTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedChartTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: tab == .pacientes ? "person.3.fill" : "heart.text.clipboard")
                                    .font(.system(size: 13))
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(selectedChartTab == tab ? (tab == .pacientes ? AppTheme.primaryGreen : .pink) : AppTheme.textMuted)
                            .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(selectedChartTab == tab ? (tab == .pacientes ? AppTheme.primaryGreen : .pink) : Color.clear)
                                .frame(height: 3)
                                .cornerRadius(1.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.spacingMD)

            Divider()
                .padding(.horizontal, AppTheme.spacingMD)

            // Chart content
            Group {
                if selectedChartTab == .pacientes {
                    pacientesChartContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    tratamientosChartContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .padding(AppTheme.spacingMD)
            .animation(.easeInOut(duration: 0.25), value: selectedChartTab)
        }
        .cardStyle()
    }

    // MARK: - Pacientes Chart Content

    private var pacientesChartContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let dataCount = CGFloat(viewModel.pacientesData.count)
                let dynamicBarWidth = max(20, min(50, (availableWidth - (dataCount - 1) * 8) / dataCount))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(viewModel.pacientesData) { data in
                            VStack(spacing: 6) {
                                Text("\(data.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(data.count > 0 ? AppTheme.primaryGreen : AppTheme.textMuted)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(
                                        width: dynamicBarWidth,
                                        height: max(CGFloat(data.count) * barHeightMultiplier, data.count > 0 ? 8 : 4)
                                    )
                                    .shadow(color: AppTheme.primaryGreen.opacity(0.3), radius: 4, x: 0, y: 2)

                                Text(data.month)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .frame(width: dynamicBarWidth)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                }
            }
            .frame(height: 130)

            // Stats row
            HStack(spacing: 12) {
                ChartStatCard(
                    title: "Total Mes",
                    value: "\(viewModel.totalPacientesMes)",
                    icon: "person.fill",
                    color: AppTheme.textPrimary,
                    backgroundColor: AppTheme.backgroundSecondary
                )

                ChartStatCard(
                    title: "Citas Hoy",
                    value: "\(viewModel.citasHoy)",
                    icon: "calendar",
                    color: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.primaryGreen.opacity(0.1)
                )

                ChartStatCard(
                    title: "Tasa Éxito",
                    value: String(format: "%.1f%%", viewModel.tasaExito),
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color(hex: "388E3C"),
                    backgroundColor: Color(hex: "388E3C").opacity(0.1)
                )
            }
        }
    }

    // MARK: - Tratamientos Donut Chart Content

    private var tratamientosChartContent: some View {
        VStack(spacing: AppTheme.spacingMD) {
            // Donut chart
            HStack(spacing: AppTheme.spacingMD) {
                ZStack {
                    let total = viewModel.tratamientosTipoData.reduce(0) { $0 + $1.count }
                    let slices = computeSlices()

                    ForEach(Array(slices.enumerated()), id: \.offset) { index, slice in
                        Circle()
                            .trim(from: slice.start, to: slice.end)
                            .stroke(slice.color, style: StrokeStyle(lineWidth: 24, lineCap: .butt))
                            .rotationEffect(.degrees(-90))
                    }

                    // Center label
                    VStack(spacing: 2) {
                        Text("\(total)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Total")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .frame(width: 130, height: 130)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.tratamientosTipoData) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)

                            Text(item.tipo)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text("\(item.count)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }

            // Stats row
            HStack(spacing: 12) {
                ChartStatCard(
                    title: "En Curso",
                    value: "\(viewModel.tratamientosEnCurso)",
                    icon: "arrow.triangle.2.circlepath",
                    color: Color(hex: "4A90D9"),
                    backgroundColor: Color(hex: "4A90D9").opacity(0.1)
                )

                ChartStatCard(
                    title: "Positivos",
                    value: "\(viewModel.tratamientosPositivos)",
                    icon: "checkmark.circle.fill",
                    color: Color(hex: "388E3C"),
                    backgroundColor: Color(hex: "388E3C").opacity(0.1)
                )

                ChartStatCard(
                    title: "Pendientes",
                    value: "\(viewModel.notasPendientes)",
                    icon: "clock.fill",
                    color: .orange,
                    backgroundColor: Color.orange.opacity(0.1)
                )
            }
        }
    }

    private struct DonutSlice {
        let start: CGFloat
        let end: CGFloat
        let color: Color
    }

    private func computeSlices() -> [DonutSlice] {
        let total = CGFloat(viewModel.tratamientosTipoData.reduce(0) { $0 + $1.count })
        guard total > 0 else { return [] }

        var slices: [DonutSlice] = []
        var currentAngle: CGFloat = 0

        for item in viewModel.tratamientosTipoData {
            let fraction = CGFloat(item.count) / total
            let slice = DonutSlice(
                start: currentAngle,
                end: currentAngle + fraction,
                color: item.color
            )
            slices.append(slice)
            currentAngle += fraction
        }

        return slices
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            Text("Acciones Rápidas")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.spacingMD) {
                DashboardCard(
                    title: "Notas Médicas",
                    icon: "stethoscope",
                    color: Color(hex: "4A90D9")
                ) {
                    showNotasMedicas = true
                }

                DashboardCard(
                    title: "Tratamientos",
                    icon: "heart.text.clipboard",
                    color: .pink
                ) {
                    showTratamientos = true
                }
            }
        }
    }
}

// MARK: - Compact Notification Row

struct CompactNotificationRow: View {
    let notification: DashboardNotification

    var body: some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: notification.icon)
                .font(.system(size: 12))
                .foregroundColor(notification.iconColor)
                .frame(width: 20)

            Text(notification.title)
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            Text(notification.timeAgo)
                .font(AppTheme.caption2)
                .foregroundColor(AppTheme.textMuted)
        }
        .padding(.vertical, AppTheme.spacingXS)
    }
}

// MARK: - Chart Stat Card

struct ChartStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let backgroundColor: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
