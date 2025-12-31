// APIError.swift
// TAG2
//
// Network and API error types

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case tokenExpired
    case serverError
    case noData
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let message):
            return message ?? "HTTP Error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please sign in again"
        case .tokenExpired:
            return "Session expired - please sign in again"
        case .serverError:
            return "Server error - please try again later"
        case .noData:
            return "No data received from server"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

enum FileMakerError: LocalizedError {
    case authenticationFailed
    case tokenExpired
    case recordNotFound
    case validationError(String)
    case scriptError(String)
    case submissionFailed
    case invalidResponse(String)

    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .recordNotFound:
            return "Record not found."
        case .validationError(let message):
            return "Validation error: \(message)"
        case .scriptError(let message):
            return "Script error: \(message)"
        case .submissionFailed:
            return "Failed to submit. Please try again."
        case .invalidResponse(let message):
            return message
        }
    }
}
