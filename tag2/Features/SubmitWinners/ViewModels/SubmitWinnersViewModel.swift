// SubmitWinnersViewModel.swift
// TAG2
//
// Submit winners business logic

import Foundation
import Combine

@MainActor
class SubmitWinnersViewModel: ObservableObject {
    // MARK: - Published State

    @Published var selectedProgramType: ProgramType = .monthly
    @Published var availableAwards: [Award] = []
    @Published var selectedAward: Award?

    @Published var winnerName = ""
    @Published var winnerTitle = ""
    @Published var reason = ""

    @Published var isLoadingAwards = false
    @Published var isSubmitting = false
    @Published var showConfetti = false
    @Published var showSuccessAlert = false

    @Published var errorMessage: String?
    @Published var validationErrors: [String: String] = [:]

    // MARK: - Dependencies

    private let companyId: String
    private let locationId: String

    // MARK: - Computed Properties

    var filteredAwards: [Award] {
        availableAwards.filter { award in
            award.programType == selectedProgramType && award.isCurrentlyActive
        }
    }

    var canSubmit: Bool {
        selectedAward != nil &&
        !winnerName.trimmed.isEmpty &&
        !winnerTitle.trimmed.isEmpty &&
        validationErrors.isEmpty
    }

    var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
    }

    var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    // MARK: - Initialization

    init(companyId: String, locationId: String) {
        self.companyId = companyId
        self.locationId = locationId
    }

    // Convenience initializer with mock data for previews
    convenience init() {
        self.init(companyId: "MOCK-001", locationId: "LOC-001")
    }

    // MARK: - Load Awards

    func loadAvailableAwards() async {
        isLoadingAwards = true
        errorMessage = nil

        defer { isLoadingAwards = false }

        do {
            availableAwards = try await FileMakerService.shared.getActiveAwardTitles(
                customerId: companyId
            )

            // If no awards from API, use mock data for development
            if availableAwards.isEmpty {
                availableAwards = Award.mockList
            }
        } catch {
            errorMessage = "Failed to load awards. Please try again."
            // Use mock data as fallback
            availableAwards = Award.mockList
        }
    }

    // MARK: - Select Award

    func selectAward(_ award: Award) {
        selectedAward = award
        clearValidationErrors()
    }

    // MARK: - Validation

    func validateForm() -> Bool {
        validationErrors.removeAll()

        if winnerName.trimmed.isEmpty {
            validationErrors["winnerName"] = "Winner name is required"
        }

        if winnerTitle.trimmed.isEmpty {
            validationErrors["winnerTitle"] = "Winner title is required"
        }

        if selectedAward == nil {
            validationErrors["award"] = "Please select an award"
        }

        return validationErrors.isEmpty
    }

    func clearValidationErrors() {
        validationErrors.removeAll()
    }

    // MARK: - Submit Winner

    func submitWinner() async -> Bool {
        guard validateForm(), let award = selectedAward else {
            return false
        }

        isSubmitting = true
        errorMessage = nil

        defer { isSubmitting = false }

        do {
            let submission = WinnerSubmission(
                winnerName: winnerName.trimmed,
                winnerTitle: winnerTitle.trimmed,
                awardId: award.id,
                companyId: companyId,
                locationId: locationId,
                month: currentMonth,
                year: currentYear,
                reason: reason.trimmed.isEmpty ? nil : reason.trimmed
            )

            let success = try await FileMakerService.shared.submitWinner(submission)

            if success {
                // Play success sound and show confetti
                AudioService.shared.playSuccessSound()
                showConfetti = true

                // Hide confetti after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.showConfetti = false
                    self.showSuccessAlert = true
                }

                return true
            } else {
                errorMessage = "Submission failed. Please try again."
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Reset Form

    func resetForm() {
        winnerName = ""
        winnerTitle = ""
        reason = ""
        selectedAward = nil
        validationErrors.removeAll()
        errorMessage = nil
        showConfetti = false
        showSuccessAlert = false
    }
}
