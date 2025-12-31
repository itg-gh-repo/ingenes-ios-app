// LocationSelectionView.swift
// TAG2
//
// Location picker for multi-location users

import SwiftUI

struct LocationSelectionView: View {
    @Environment(\.dismiss) var dismiss
    let locations: [Location]
    let onSelect: (Location) -> Void

    @State private var selectedLocation: Location?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Location List
                locationList
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let location = selectedLocation {
                            onSelect(location)
                            dismiss()
                        }
                    }
                    .disabled(selectedLocation == nil)
                    .foregroundColor(selectedLocation == nil ? .gray : AppTheme.primaryGreen)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: AppTheme.spacingSM) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.primaryGreen)

            Text("Multiple Locations")
                .font(AppTheme.headline)

            Text("You have access to multiple locations. Please select one to continue.")
                .font(AppTheme.callout)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, AppTheme.spacingLG)
        .background(AppTheme.backgroundSecondary)
    }

    // MARK: - Location List

    private var locationList: some View {
        List(locations) { location in
            LocationRow(
                location: location,
                isSelected: selectedLocation?.id == location.id
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: AppTheme.animationFast)) {
                    selectedLocation = location
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Location Row

struct LocationRow: View {
    let location: Location
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppTheme.spacingMD) {
            // Icon
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary)

            // Info
            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                Text(location.name)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Text(location.storeName)
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Selection Indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.primaryGreen)
            }
        }
        .padding(.vertical, AppTheme.spacingSM)
        .background(isSelected ? AppTheme.primaryGreen.opacity(0.1) : Color.clear)
        .cornerRadius(AppTheme.radiusMD)
    }
}

// MARK: - Preview

#Preview {
    LocationSelectionView(
        locations: Location.mockList,
        onSelect: { location in
            print("Selected: \(location.name)")
        }
    )
}
