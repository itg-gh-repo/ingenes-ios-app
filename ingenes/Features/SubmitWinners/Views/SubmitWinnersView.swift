// SubmitWinnersView.swift
// Ingenes
//
// Submit winners main screen

import SwiftUI
import Combine

struct SubmitWinnersView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SubmitWinnersViewModel()

    var body: some View {
        ZStack {
            // Main Content
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    // Program Type Picker
                    programTypePicker

                    // Awards Grid
                    awardsSection

                    // Winner Form (shown when award selected)
                    if viewModel.selectedAward != nil {
                        WinnerFormView(viewModel: viewModel)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Submit Button
                    if viewModel.selectedAward != nil {
                        submitButton
                    }

                    // Error Message
                    errorSection
                }
                .padding(AppTheme.spacingMD)
            }
            .scrollDismissesKeyboard(.interactively)

            // Confetti Overlay
            if viewModel.showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle("Submit Winner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .loadingOverlay(isLoading: viewModel.isSubmitting, message: "Submitting...")
        .task {
            if let user = appState.currentUser {
                // Reinitialize viewModel with actual user data
                // For now, load awards with current config
            }
            await viewModel.loadAvailableAwards()
        }
        .alert("Success!", isPresented: $viewModel.showSuccessAlert) {
            Button("Submit Another") {
                viewModel.resetForm()
            }
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Winner submitted successfully!")
        }
        .animation(.easeInOut(duration: AppTheme.animationNormal), value: viewModel.selectedAward != nil)
    }

    // MARK: - Program Type Picker

    private var programTypePicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("Award Type")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textSecondary)

            Picker("Award Type", selection: $viewModel.selectedProgramType) {
                ForEach(ProgramType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedProgramType) { _, _ in
                viewModel.selectedAward = nil
            }
        }
    }

    // MARK: - Awards Section

    private var awardsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            Text("Select Award")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            if viewModel.isLoadingAwards {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, AppTheme.spacingXL)
                    Spacer()
                }
            } else if viewModel.filteredAwards.isEmpty {
                emptyAwardsView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.spacingMD) {
                    ForEach(viewModel.filteredAwards) { award in
                        AwardCard(
                            award: award,
                            isSelected: viewModel.selectedAward?.id == award.id
                        ) {
                            withAnimation {
                                viewModel.selectAward(award)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyAwardsView: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Image(systemName: "trophy")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textMuted)

            Text("No \(viewModel.selectedProgramType.displayName.lowercased()) awards available")
                .font(AppTheme.callout)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingXL)
        .cardStyle()
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            Task {
                await viewModel.submitWinner()
            }
        } label: {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("Submit Winner")
            }
        }
        .buttonStyle(PrimaryButtonStyle(
            isLoading: viewModel.isSubmitting,
            isDisabled: !viewModel.canSubmit
        ))
        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
        .padding(.top, AppTheme.spacingMD)
    }

    // MARK: - Error Section

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.errorColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .transition(.opacity)
        }
    }
}

// MARK: - Award Card

struct AwardCard: View {
    let award: Award
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.spacingSM) {
                // Icon
                Image(systemName: award.programType.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : AppTheme.primaryGreen)

                // Name
                Text(award.name)
                    .font(AppTheme.callout)
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.spacingMD)
            .background(isSelected ? AppTheme.primaryGreen : AppTheme.backgroundPrimary)
            .cornerRadius(AppTheme.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLG)
                    .stroke(isSelected ? AppTheme.primaryGreen : AppTheme.backgroundSecondary, lineWidth: 2)
            )
            .shadow(color: isSelected ? AppTheme.primaryGreen.opacity(0.3) : AppTheme.shadowLight, radius: 4)
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubmitWinnersView()
    }
    .environmentObject(AppState())
}
