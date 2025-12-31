// InputField.swift
// TAG2
//
// Reusable styled input field components

import SwiftUI

struct StyledTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
            Text(title)
                .font(AppTheme.caption)
                .foregroundColor(errorMessage != nil ? AppTheme.errorColor : AppTheme.textSecondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                }
            }
            .autocorrectionDisabled()
            .padding(AppTheme.spacingMD)
            .background(AppTheme.backgroundSecondary)
            .cornerRadius(AppTheme.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .stroke(errorMessage != nil ? AppTheme.errorColor : Color.clear, lineWidth: 1)
            )

            if let error = errorMessage {
                Text(error)
                    .font(AppTheme.caption2)
                    .foregroundColor(AppTheme.errorColor)
            }
        }
    }
}

// MARK: - Text Area

struct StyledTextArea: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
            Text(title)
                .font(AppTheme.caption)
                .foregroundColor(errorMessage != nil ? AppTheme.errorColor : AppTheme.textSecondary)

            TextEditor(text: $text)
                .frame(minHeight: minHeight)
                .padding(AppTheme.spacingSM)
                .background(AppTheme.backgroundSecondary)
                .cornerRadius(AppTheme.radiusMD)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                        .stroke(errorMessage != nil ? AppTheme.errorColor : Color.clear, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.textMuted)
                            .padding(.horizontal, AppTheme.spacingMD)
                            .padding(.vertical, AppTheme.spacingMD)
                            .allowsHitTesting(false)
                    }
                }

            if let error = errorMessage {
                Text(error)
                    .font(AppTheme.caption2)
                    .foregroundColor(AppTheme.errorColor)
            }
        }
    }
}

// MARK: - Search Field

struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    var onCommit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.textSecondary)

            TextField(placeholder, text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit {
                    onCommit?()
                }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(AppTheme.spacingMD)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.radiusMD)
    }
}

// MARK: - Previews

#Preview("Text Field") {
    VStack(spacing: 20) {
        StyledTextField(
            title: "Username",
            placeholder: "Enter username",
            text: .constant("")
        )

        StyledTextField(
            title: "Email",
            placeholder: "Enter email",
            text: .constant("test@example.com"),
            keyboardType: .emailAddress
        )

        StyledTextField(
            title: "Password",
            placeholder: "Enter password",
            text: .constant(""),
            isSecure: true
        )

        StyledTextField(
            title: "With Error",
            placeholder: "Enter value",
            text: .constant(""),
            errorMessage: "This field is required"
        )
    }
    .padding()
}

#Preview("Text Area") {
    StyledTextArea(
        title: "Reason for Award",
        placeholder: "Enter the reason for this award...",
        text: .constant("")
    )
    .padding()
}

#Preview("Search Field") {
    SearchField(
        placeholder: "Search winners...",
        text: .constant("")
    )
    .padding()
}
