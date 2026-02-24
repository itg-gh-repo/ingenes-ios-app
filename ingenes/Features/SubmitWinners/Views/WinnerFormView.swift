// WinnerFormView.swift
// Ingenes
//
// Winner details form

import SwiftUI

struct WinnerFormView: View {
    @ObservedObject var viewModel: SubmitWinnersViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case title
        case reason
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
            // Section Header
            HStack {
                Text("Winner Details")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                if let award = viewModel.selectedAward {
                    Text(award.name)
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.primaryGreen)
                        .padding(.horizontal, AppTheme.spacingSM)
                        .padding(.vertical, AppTheme.spacingXS)
                        .background(AppTheme.primaryGreen.opacity(0.1))
                        .cornerRadius(AppTheme.radiusSM)
                }
            }

            // Form Fields
            VStack(spacing: AppTheme.spacingMD) {
                // Winner Name
                StyledTextField(
                    title: "Winner Name *",
                    placeholder: "Enter winner's full name",
                    text: $viewModel.winnerName,
                    autocapitalization: .words,
                    errorMessage: viewModel.validationErrors["winnerName"]
                )
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .title }
                .onChange(of: viewModel.winnerName) { _, _ in
                    viewModel.clearValidationErrors()
                }

                // Winner Title
                StyledTextField(
                    title: "Job Title *",
                    placeholder: "Enter winner's job title",
                    text: $viewModel.winnerTitle,
                    autocapitalization: .words,
                    errorMessage: viewModel.validationErrors["winnerTitle"]
                )
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit { focusedField = .reason }
                .onChange(of: viewModel.winnerTitle) { _, _ in
                    viewModel.clearValidationErrors()
                }

                // Reason (Optional)
                StyledTextArea(
                    title: "Reason for Award (Optional)",
                    placeholder: "Why is this person deserving of this award?",
                    text: $viewModel.reason,
                    minHeight: 100
                )
                .focused($focusedField, equals: .reason)
            }
            .padding(AppTheme.spacingMD)
            .cardStyle()
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        WinnerFormView(viewModel: SubmitWinnersViewModel())
            .padding()
    }
}
