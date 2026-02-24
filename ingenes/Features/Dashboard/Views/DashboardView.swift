// DashboardView.swift
// Ingenes
//
// Main dashboard screen

import SwiftUI
import Combine

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: DashboardViewModel

    @State private var showPedidos = false
    @State private var showProyectos = false
    @State private var showSideMenu = false
    @State private var selectedChartTab: ChartTab = .proyectos

    // MARK: - Chart Tab

    enum ChartTab: String, CaseIterable {
        case proyectos = "Proyectos"
        case presupuesto = "Presupuesto"
    }

    // MARK: - Bar Chart Sizing

    /// Dynamic bar width based on period
    private var barWidth: CGFloat {
        switch viewModel.selectedPeriod {
        case .threeMonths: return 80
        case .sixMonths: return 45
        case .oneYear, .allTime: return 30
        }
    }

    /// Dynamic bar height multiplier based on max value
    private var barHeightMultiplier: CGFloat {
        let maxCount = viewModel.projectsData.map { $0.count }.max() ?? 1
        if maxCount == 0 { return 1 }
        return 80 / CGFloat(maxCount)
    }

    /// Dynamic bar height multiplier for budget chart
    private var budgetBarHeightMultiplier: CGFloat {
        let maxAmount = viewModel.budgetData.map { $0.amount }.max() ?? 1
        if maxAmount == 0 { return 1 }
        return 80 / maxAmount
    }

    init() {
        // Initialize with a placeholder - will be updated on appear
        _viewModel = StateObject(wrappedValue: DashboardViewModel(user: User.mock))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    // Welcome Header
                    welcomeHeader

                    // Tabbed Charts Card (Proyectos / Presupuesto)
                    tabbedChartsCard

                    // Quick Actions
                    quickActionsSection

                    // Notifications Card (compact)
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
            .fullScreenCover(isPresented: $showPedidos) {
                NavigationStack {
                    PedidosView()
                }
            }
            .fullScreenCover(isPresented: $showProyectos) {
                NavigationStack {
                    ProyectosView()
                        .environmentObject(appState)
                }
            }
            .task {
                if let user = appState.currentUser {
                    // Re-initialize viewModel with actual user
                    await MainActor.run {
                        // This is a workaround since we can't reinitialize StateObject
                    }
                }
                await viewModel.loadDashboardData()
            }
        }
    }

    // MARK: - Navigation

    private func handleMenuNavigation(_ destination: MenuDestination) {
        switch destination {
        case .dashboard:
            // Already on dashboard, do nothing
            break
        case .proyectos:
            showProyectos = true
        case .pedidos:
            showPedidos = true
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

    // MARK: - Notifications Card (Compact)

    private var notificationsCard: some View {
        VStack(spacing: AppTheme.spacingSM) {
            // Header with badge
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(AppTheme.primaryGreen)

                Text("Notificaciones")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                // Badge
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

            // Compact notification list (just titles)
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
        selectedChartTab == .proyectos ? AppTheme.primaryGreen : Color.orange
    }

    private var tabbedChartsCard: some View {
        VStack(spacing: 0) {
            // Header with icon and period picker
            HStack(alignment: .center) {
                // Chart icon with color indicator
                Image(systemName: selectedChartTab == .proyectos ? "chart.bar.fill" : "dollarsign.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(currentTabColor)
                    .animation(.easeInOut(duration: 0.2), value: selectedChartTab)

                Text(selectedChartTab == .proyectos ? "Proyectos" : "Presupuesto")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                // Period Picker - pill style
                Menu {
                    ForEach(ProjectPeriod.allCases, id: \.self) { period in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.selectedPeriod = period
                            }
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
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.top, AppTheme.spacingMD)
            .padding(.bottom, AppTheme.spacingSM)

            // Segmented Tab Control
            HStack(spacing: 0) {
                ForEach(ChartTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedChartTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: tab == .proyectos ? "folder.fill" : "banknote.fill")
                                    .font(.system(size: 13))
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(selectedChartTab == tab ? (tab == .proyectos ? AppTheme.primaryGreen : .orange) : AppTheme.textMuted)
                            .frame(maxWidth: .infinity)

                            // Active indicator bar
                            Rectangle()
                                .fill(selectedChartTab == tab ? (tab == .proyectos ? AppTheme.primaryGreen : .orange) : Color.clear)
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

            // Chart content with transition
            Group {
                if selectedChartTab == .proyectos {
                    projectsChartContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    budgetChartContent
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

    // MARK: - Projects Chart Content

    private var projectsChartContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            // Bar chart with gradient bars
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let dataCount = CGFloat(viewModel.projectsData.count)
                let dynamicBarWidth = max(20, min(50, (availableWidth - (dataCount - 1) * 8) / dataCount))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(viewModel.projectsData.enumerated()), id: \.element.id) { index, data in
                            VStack(spacing: 6) {
                                // Value label
                                Text("\(data.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(data.count > 0 ? AppTheme.primaryGreen : AppTheme.textMuted)

                                // Animated bar with gradient
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

                                // Month label
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

            // Stats cards row
            HStack(spacing: 12) {
                ChartStatCard(
                    title: "Total",
                    value: "\(viewModel.totalProjects)",
                    icon: "square.stack.3d.up.fill",
                    color: AppTheme.textPrimary,
                    backgroundColor: AppTheme.backgroundSecondary
                )

                ChartStatCard(
                    title: "Activos",
                    value: "\(viewModel.activeProjects)",
                    icon: "bolt.fill",
                    color: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.primaryGreen.opacity(0.1)
                )

                ChartStatCard(
                    title: "Cerrados",
                    value: "\(viewModel.completedProjects)",
                    icon: "checkmark.circle.fill",
                    color: .blue,
                    backgroundColor: Color.blue.opacity(0.1)
                )
            }
        }
    }

    // MARK: - Budget Chart Content

    private var budgetChartContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            // Bar chart with gradient bars
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let dataCount = CGFloat(viewModel.budgetData.count)
                let dynamicBarWidth = max(20, min(50, (availableWidth - (dataCount - 1) * 8) / dataCount))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(viewModel.budgetData) { data in
                            VStack(spacing: 6) {
                                // Value label
                                Text(data.formattedAmount)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(data.amount > 0 ? .orange : AppTheme.textMuted)

                                // Animated bar with gradient
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange, Color.orange.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(
                                        width: dynamicBarWidth,
                                        height: max(CGFloat(data.amount * budgetBarHeightMultiplier), data.amount > 0 ? 8 : 4)
                                    )
                                    .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)

                                // Month label
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

            // Total Budget card - prominent display
            HStack(spacing: 16) {
                // Total budget highlight
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Presupuesto")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Text(viewModel.totalBudgetFormatted)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                // Project count indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(viewModel.totalProjects)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("proyectos")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            .padding(12)
            .background(Color.orange.opacity(0.08))
            .cornerRadius(12)
        }
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
                    title: "Proyectos",
                    icon: "folder.fill",
                    color: .blue
                ) {
                    showProyectos = true
                }

                DashboardCard(
                    title: "Pedidos",
                    icon: "shippingbox.fill",
                    color: .orange
                ) {
                    showPedidos = true
                }
            }
        }
    }

    // MARK: - Recent Winners

    private var recentWinnersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            HStack {
                Text("Ganadores Recientes")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button("Ver Todos") {
                    // TODO: Navigate to History
                }
                .font(AppTheme.callout)
                .foregroundColor(AppTheme.primaryGreen)
            }

            if viewModel.isLoading && viewModel.recentWinners.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, AppTheme.spacingXL)
            } else if viewModel.recentWinners.isEmpty {
                emptyWinnersView
            } else {
                VStack(spacing: AppTheme.spacingSM) {
                    ForEach(viewModel.recentWinners) { winner in
                        WinnerRow(winner: winner)
                    }
                }
            }
        }
    }

    private var emptyWinnersView: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Image(systemName: "trophy")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textMuted)

            Text("Aún no hay ganadores enviados")
                .font(AppTheme.callout)
                .foregroundColor(AppTheme.textSecondary)

            Text("¡Envía tu primer ganador para comenzar!")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingXL)
        .cardStyle()
    }
}

// MARK: - Winner Row

struct WinnerRow: View {
    let winner: Winner

    var body: some View {
        HStack(spacing: AppTheme.spacingMD) {
            // Icon
            Circle()
                .fill(AppTheme.primaryGreen.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(AppTheme.primaryGreen)
                )

            // Info
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text(winner.name)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Text(winner.awardName)
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Status
            VStack(alignment: .trailing, spacing: AppTheme.spacingXS) {
                Text(winner.displayDate)
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.textSecondary)

                StatusBadge(status: winner.workOrderStatus)
            }
        }
        .padding(AppTheme.spacingMD)
        .cardStyle()
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status)
            .font(AppTheme.caption2)
            .foregroundColor(statusColor)
            .padding(.horizontal, AppTheme.spacingSM)
            .padding(.vertical, AppTheme.spacingXS)
            .background(statusColor.opacity(0.2))
            .cornerRadius(AppTheme.radiusSM)
    }

    private var statusColor: Color {
        switch status.lowercased() {
        case "shipped": return AppTheme.successColor
        case "processing": return AppTheme.warningColor
        case "pending": return Color.yellow
        default: return AppTheme.textSecondary
        }
    }
}

// MARK: - Compact Notification Row

struct CompactNotificationRow: View {
    let notification: DashboardNotification

    var body: some View {
        HStack(spacing: AppTheme.spacingSM) {
            // Small icon
            Image(systemName: notification.icon)
                .font(.system(size: 12))
                .foregroundColor(notification.iconColor)
                .frame(width: 20)

            // Title only
            Text(notification.title)
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            // Time
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
            // Icon
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            // Value
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)

            // Title
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
