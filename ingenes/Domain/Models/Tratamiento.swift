// Tratamiento.swift
// Ingenes
//
// Treatment model for fertility clinic with embryo timeline

import Foundation
import SwiftUI

// MARK: - Enums

enum TipoTratamiento: String, CaseIterable, Identifiable {
    case donacionOvulos = "Donación de Óvulos"
    case fivPropios = "FIV Propios"
    case iad = "IAD"
    case descongelacion = "Descongelación"
    case fivMore = "FIV More"
    case fivDConocida = "FIV D. Conocida"
    case congeladosPropios = "Congelados Propios"
    case ovodonBlueDonors = "Ovodón Blue Donors"
    case congeladosMore = "Congelados More"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .donacionOvulos: return Color(hex: "E91E63")   // Pink
        case .fivPropios: return Color(hex: "4A90D9")       // Blue
        case .iad: return Color(hex: "9C27B0")              // Purple
        case .descongelacion: return Color(hex: "00BCD4")    // Cyan
        case .fivMore: return Color(hex: "FF9800")           // Orange
        case .fivDConocida: return Color(hex: "4CAF50")      // Green
        case .congeladosPropios: return Color(hex: "607D8B") // Blue Grey
        case .ovodonBlueDonors: return Color(hex: "3F51B5")  // Indigo
        case .congeladosMore: return Color(hex: "795548")     // Brown
        }
    }

    var shortName: String {
        switch self {
        case .donacionOvulos: return "DON"
        case .fivPropios: return "FIV-P"
        case .iad: return "IAD"
        case .descongelacion: return "DESC"
        case .fivMore: return "FIV-M"
        case .fivDConocida: return "FIV-DC"
        case .congeladosPropios: return "CONG-P"
        case .ovodonBlueDonors: return "OVO-BD"
        case .congeladosMore: return "CONG-M"
        }
    }
}

enum ResultadoTratamiento: String, CaseIterable {
    case enCurso = "En Curso"
    case positivo = "Positivo"
    case negativo = "Negativo"
    case cancelado = "Cancelado"
    case pendiente = "Pendiente"

    var color: Color {
        switch self {
        case .enCurso: return Color(hex: "4A90D9")
        case .positivo: return Color(hex: "388E3C")
        case .negativo: return Color(hex: "D32F2F")
        case .cancelado: return .gray
        case .pendiente: return .orange
        }
    }

    var icon: String {
        switch self {
        case .enCurso: return "arrow.triangle.2.circlepath"
        case .positivo: return "checkmark.circle.fill"
        case .negativo: return "xmark.circle.fill"
        case .cancelado: return "minus.circle.fill"
        case .pendiente: return "clock.fill"
        }
    }
}

enum EmbryoEstado: String, CaseIterable {
    case viable = "Viable"
    case transferido = "Transferido"
    case noViable = "No Viable"
    case congelado = "Congelado"
    case enDesarrollo = "En Desarrollo"

    var color: Color {
        switch self {
        case .viable: return Color(hex: "4CAF50")
        case .transferido: return Color(hex: "4A90D9")
        case .noViable: return Color(hex: "D32F2F")
        case .congelado: return Color(hex: "00BCD4")
        case .enDesarrollo: return .orange
        }
    }

    var icon: String {
        switch self {
        case .viable: return "checkmark.circle"
        case .transferido: return "arrow.right.circle.fill"
        case .noViable: return "xmark.circle"
        case .congelado: return "snowflake"
        case .enDesarrollo: return "circle.dotted"
        }
    }
}

// MARK: - Embryo Day

struct EmbryoDay: Identifiable, Equatable {
    let id = UUID()
    let dia: Int              // 0-8
    let grado: String?        // e.g. "5BB", "4AA", "8cel"
    let estado: EmbryoEstado
    let numeroCelulas: Int?

    var diaTexto: String {
        "D\(dia)"
    }
}

// MARK: - Tratamiento

struct Tratamiento: Identifiable, Equatable {
    let id: String
    let paciente: Paciente
    let nIni: String             // Treatment number
    let nombreTratamiento: String
    let tipoTratamiento: TipoTratamiento
    let seguro: Bool
    let tipoCiclo: String        // "Natural", "Estimulado", "Semi-natural"
    let etiologiaFemenina: String
    let fechaTransfer: Date?
    let resultado: ResultadoTratamiento
    let embriones: [EmbryoDay]

    var fechaTransferFormateada: String? {
        guard let fecha = fechaTransfer else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: fecha)
    }

    var embrioneViableCount: Int {
        embriones.filter { $0.estado == .viable || $0.estado == .transferido || $0.estado == .congelado }.count
    }

    static func == (lhs: Tratamiento, rhs: Tratamiento) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Mock Data

extension Tratamiento {
    static let mockList: [Tratamiento] = {
        let calendar = Calendar.current
        let today = Date()
        let pacientes = Paciente.mockList

        return [
            // 1. FIV Propios - Positivo (completed with embryo timeline)
            Tratamiento(
                id: "TRT-001", paciente: pacientes[0], nIni: "INI-2024-0156",
                nombreTratamiento: "FIV con óvulos propios", tipoTratamiento: .fivPropios,
                seguro: true, tipoCiclo: "Estimulado", etiologiaFemenina: "Factor tubárico",
                fechaTransfer: calendar.date(byAdding: .day, value: -21, to: today),
                resultado: .positivo,
                embriones: [
                    EmbryoDay(dia: 0, grado: "MII", estado: .viable, numeroCelulas: 1),
                    EmbryoDay(dia: 1, grado: "2PN", estado: .viable, numeroCelulas: 2),
                    EmbryoDay(dia: 2, grado: "4cel", estado: .viable, numeroCelulas: 4),
                    EmbryoDay(dia: 3, grado: "8cel", estado: .viable, numeroCelulas: 8),
                    EmbryoDay(dia: 4, grado: "Mórula", estado: .viable, numeroCelulas: nil),
                    EmbryoDay(dia: 5, grado: "5AA", estado: .transferido, numeroCelulas: nil),
                ]
            ),
            // 2. Donación de Óvulos - En Curso
            Tratamiento(
                id: "TRT-002", paciente: pacientes[1], nIni: "INI-2024-0189",
                nombreTratamiento: "Ovodonación", tipoTratamiento: .donacionOvulos,
                seguro: true, tipoCiclo: "Estimulado", etiologiaFemenina: "Baja reserva ovárica",
                fechaTransfer: calendar.date(byAdding: .day, value: 5, to: today),
                resultado: .enCurso,
                embriones: [
                    EmbryoDay(dia: 0, grado: "MII", estado: .viable, numeroCelulas: 1),
                    EmbryoDay(dia: 1, grado: "2PN", estado: .viable, numeroCelulas: 2),
                    EmbryoDay(dia: 2, grado: "4cel", estado: .enDesarrollo, numeroCelulas: 4),
                ]
            ),
            // 3. FIV Propios - En Curso (full timeline)
            Tratamiento(
                id: "TRT-003", paciente: pacientes[2], nIni: "INI-2024-0201",
                nombreTratamiento: "FIV óvulos propios", tipoTratamiento: .fivPropios,
                seguro: false, tipoCiclo: "Estimulado", etiologiaFemenina: "Endometriosis",
                fechaTransfer: nil,
                resultado: .enCurso,
                embriones: [
                    EmbryoDay(dia: 0, grado: "MII", estado: .viable, numeroCelulas: 1),
                    EmbryoDay(dia: 1, grado: "2PN", estado: .viable, numeroCelulas: 2),
                    EmbryoDay(dia: 2, grado: "4cel", estado: .viable, numeroCelulas: 4),
                    EmbryoDay(dia: 3, grado: "8cel", estado: .viable, numeroCelulas: 8),
                    EmbryoDay(dia: 4, grado: "Mórula", estado: .viable, numeroCelulas: nil),
                    EmbryoDay(dia: 5, grado: "4BB", estado: .enDesarrollo, numeroCelulas: nil),
                ]
            ),
            // 4. IAD - Pendiente
            Tratamiento(
                id: "TRT-004", paciente: pacientes[3], nIni: "INI-2024-0215",
                nombreTratamiento: "Inseminación artificial", tipoTratamiento: .iad,
                seguro: true, tipoCiclo: "Natural", etiologiaFemenina: "Factor masculino",
                fechaTransfer: calendar.date(byAdding: .day, value: 10, to: today),
                resultado: .pendiente,
                embriones: []
            ),
            // 5. Descongelación - Positivo
            Tratamiento(
                id: "TRT-005", paciente: pacientes[4], nIni: "INI-2024-0178",
                nombreTratamiento: "Transferencia de congelados", tipoTratamiento: .descongelacion,
                seguro: true, tipoCiclo: "Semi-natural", etiologiaFemenina: "Anovulación",
                fechaTransfer: calendar.date(byAdding: .day, value: -30, to: today),
                resultado: .positivo,
                embriones: [
                    EmbryoDay(dia: 0, grado: "5BB", estado: .viable, numeroCelulas: nil),
                    EmbryoDay(dia: 5, grado: "5BB", estado: .transferido, numeroCelulas: nil),
                ]
            ),
            // 6. FIV More - Negativo
            Tratamiento(
                id: "TRT-006", paciente: pacientes[5], nIni: "INI-2024-0134",
                nombreTratamiento: "FIV More", tipoTratamiento: .fivMore,
                seguro: false, tipoCiclo: "Estimulado", etiologiaFemenina: "Factor edad",
                fechaTransfer: calendar.date(byAdding: .day, value: -45, to: today),
                resultado: .negativo,
                embriones: [
                    EmbryoDay(dia: 0, grado: "MII", estado: .viable, numeroCelulas: 1),
                    EmbryoDay(dia: 1, grado: "2PN", estado: .viable, numeroCelulas: 2),
                    EmbryoDay(dia: 2, grado: "3cel", estado: .noViable, numeroCelulas: 3),
                ]
            ),
            // 7. FIV D. Conocida - En Curso
            Tratamiento(
                id: "TRT-007", paciente: pacientes[6], nIni: "INI-2024-0223",
                nombreTratamiento: "FIV Donante Conocida", tipoTratamiento: .fivDConocida,
                seguro: true, tipoCiclo: "Estimulado", etiologiaFemenina: "Falla ovárica prematura",
                fechaTransfer: calendar.date(byAdding: .day, value: 3, to: today),
                resultado: .enCurso,
                embriones: [
                    EmbryoDay(dia: 0, grado: "MII", estado: .viable, numeroCelulas: 1),
                    EmbryoDay(dia: 1, grado: "2PN", estado: .viable, numeroCelulas: 2),
                    EmbryoDay(dia: 2, grado: "4cel", estado: .viable, numeroCelulas: 4),
                    EmbryoDay(dia: 3, grado: "8cel", estado: .viable, numeroCelulas: 8),
                ]
            ),
            // 8. Congelados Propios - Positivo
            Tratamiento(
                id: "TRT-008", paciente: pacientes[7], nIni: "INI-2024-0198",
                nombreTratamiento: "Transferencia congelados propios", tipoTratamiento: .congeladosPropios,
                seguro: true, tipoCiclo: "Semi-natural", etiologiaFemenina: "SOP",
                fechaTransfer: calendar.date(byAdding: .day, value: -14, to: today),
                resultado: .positivo,
                embriones: [
                    EmbryoDay(dia: 0, grado: "4AA", estado: .viable, numeroCelulas: nil),
                    EmbryoDay(dia: 5, grado: "4AA", estado: .transferido, numeroCelulas: nil),
                ]
            ),
            // 9. Ovodón Blue Donors - En Curso
            Tratamiento(
                id: "TRT-009", paciente: pacientes[8], nIni: "INI-2024-0230",
                nombreTratamiento: "Ovodón Blue Donors", tipoTratamiento: .ovodonBlueDonors,
                seguro: false, tipoCiclo: "Estimulado", etiologiaFemenina: "Factor genético",
                fechaTransfer: nil,
                resultado: .enCurso,
                embriones: [
                    EmbryoDay(dia: 0, grado: "MII", estado: .viable, numeroCelulas: 1),
                    EmbryoDay(dia: 1, grado: "2PN", estado: .enDesarrollo, numeroCelulas: 2),
                ]
            ),
            // 10. Congelados More - Cancelado
            Tratamiento(
                id: "TRT-010", paciente: pacientes[9], nIni: "INI-2024-0145",
                nombreTratamiento: "Congelados More", tipoTratamiento: .congeladosMore,
                seguro: true, tipoCiclo: "Natural", etiologiaFemenina: "Endometriosis",
                fechaTransfer: nil,
                resultado: .cancelado,
                embriones: []
            ),
            // 11. FIV Propios - Negativo (with congelados)
            Tratamiento(
                id: "TRT-011", paciente: pacientes[0], nIni: "INI-2024-0110",
                nombreTratamiento: "FIV óvulos propios (2do ciclo)", tipoTratamiento: .fivPropios,
                seguro: true, tipoCiclo: "Estimulado", etiologiaFemenina: "Factor tubárico",
                fechaTransfer: calendar.date(byAdding: .month, value: -3, to: today),
                resultado: .negativo,
                embriones: [
                    EmbryoDay(dia: 0, grado: "MII", estado: .viable, numeroCelulas: 1),
                    EmbryoDay(dia: 1, grado: "2PN", estado: .viable, numeroCelulas: 2),
                    EmbryoDay(dia: 2, grado: "4cel", estado: .viable, numeroCelulas: 4),
                    EmbryoDay(dia: 3, grado: "6cel", estado: .viable, numeroCelulas: 6),
                    EmbryoDay(dia: 4, grado: "Mórula", estado: .viable, numeroCelulas: nil),
                    EmbryoDay(dia: 5, grado: "3BB", estado: .transferido, numeroCelulas: nil),
                    EmbryoDay(dia: 5, grado: "4AB", estado: .congelado, numeroCelulas: nil),
                ]
            ),
            // 12. Donación de Óvulos - Positivo
            Tratamiento(
                id: "TRT-012", paciente: pacientes[5], nIni: "INI-2024-0167",
                nombreTratamiento: "Ovodonación (2do intento)", tipoTratamiento: .donacionOvulos,
                seguro: true, tipoCiclo: "Estimulado", etiologiaFemenina: "Factor edad",
                fechaTransfer: calendar.date(byAdding: .day, value: -60, to: today),
                resultado: .positivo,
                embriones: [
                    EmbryoDay(dia: 0, grado: "MII", estado: .viable, numeroCelulas: 1),
                    EmbryoDay(dia: 1, grado: "2PN", estado: .viable, numeroCelulas: 2),
                    EmbryoDay(dia: 2, grado: "4cel", estado: .viable, numeroCelulas: 4),
                    EmbryoDay(dia: 3, grado: "8cel", estado: .viable, numeroCelulas: 8),
                    EmbryoDay(dia: 4, grado: "Mórula", estado: .viable, numeroCelulas: nil),
                    EmbryoDay(dia: 5, grado: "5AA", estado: .transferido, numeroCelulas: nil),
                    EmbryoDay(dia: 5, grado: "4BB", estado: .congelado, numeroCelulas: nil),
                    EmbryoDay(dia: 5, grado: "3BC", estado: .congelado, numeroCelulas: nil),
                ]
            ),
            // 13. IAD - Negativo
            Tratamiento(
                id: "TRT-013", paciente: pacientes[3], nIni: "INI-2024-0190",
                nombreTratamiento: "IAD (1er intento)", tipoTratamiento: .iad,
                seguro: true, tipoCiclo: "Natural", etiologiaFemenina: "Factor masculino",
                fechaTransfer: calendar.date(byAdding: .day, value: -40, to: today),
                resultado: .negativo,
                embriones: []
            ),
            // 14. FIV Propios - En Curso (early)
            Tratamiento(
                id: "TRT-014", paciente: pacientes[9], nIni: "INI-2024-0240",
                nombreTratamiento: "FIV óvulos propios", tipoTratamiento: .fivPropios,
                seguro: false, tipoCiclo: "Estimulado", etiologiaFemenina: "Endometriosis",
                fechaTransfer: nil,
                resultado: .enCurso,
                embriones: [
                    EmbryoDay(dia: 0, grado: "MII", estado: .viable, numeroCelulas: 1),
                ]
            ),
            // 15. Descongelación - Pendiente
            Tratamiento(
                id: "TRT-015", paciente: pacientes[2], nIni: "INI-2024-0245",
                nombreTratamiento: "Transferencia de congelados", tipoTratamiento: .descongelacion,
                seguro: true, tipoCiclo: "Semi-natural", etiologiaFemenina: "Endometriosis",
                fechaTransfer: calendar.date(byAdding: .day, value: 15, to: today),
                resultado: .pendiente,
                embriones: []
            ),
        ]
    }()

    static let mock = mockList[0]
}
