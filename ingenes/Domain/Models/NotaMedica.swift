// NotaMedica.swift
// Ingenes
//
// Medical note model for fertility clinic

import Foundation
import SwiftUI

// MARK: - Enums

enum TipoNota: String, CaseIterable, Identifiable {
    case notaMedica = "Nota Médica"
    case notaSEI = "Nota SEI"
    case notaComercial = "Nota Comercial"
    case notaCI = "Nota CI"
    case notaSM = "Nota SM"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .notaMedica: return Color(hex: "4A90D9")   // Medical blue
        case .notaSEI: return Color(hex: "7B1FA2")      // Purple
        case .notaComercial: return Color(hex: "F57C00") // Orange
        case .notaCI: return Color(hex: "388E3C")        // Green
        case .notaSM: return Color(hex: "C62828")        // Red
        }
    }

    var icon: String {
        switch self {
        case .notaMedica: return "stethoscope"
        case .notaSEI: return "heart.text.clipboard"
        case .notaComercial: return "briefcase.fill"
        case .notaCI: return "doc.text.fill"
        case .notaSM: return "cross.case.fill"
        }
    }

    var shortName: String {
        switch self {
        case .notaMedica: return "NM"
        case .notaSEI: return "SEI"
        case .notaComercial: return "COM"
        case .notaCI: return "CI"
        case .notaSM: return "SM"
        }
    }
}

enum NotaEstatus: String, CaseIterable {
    case pendiente = "Pendiente"
    case completada = "Completada"
    case revisada = "Revisada"

    var color: Color {
        switch self {
        case .pendiente: return .orange
        case .completada: return Color(hex: "4A90D9")
        case .revisada: return Color(hex: "388E3C")
        }
    }

    var icon: String {
        switch self {
        case .pendiente: return "clock.fill"
        case .completada: return "checkmark.circle.fill"
        case .revisada: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Signos Vitales

struct SignosVitales: Equatable {
    let peso: Double?            // kg
    let estatura: Double?        // cm
    let imc: Double?
    let presionArterial: String? // e.g. "120/80"
    let frecuenciaCardiaca: Int? // bpm
    let frecuenciaRespiratoria: Int? // rpm
    let saturacionO2: Int?       // %
    let temperatura: Double?     // °C
}

// MARK: - Nota Médica

struct NotaMedica: Identifiable, Equatable {
    let id: String
    let paciente: Paciente
    let tipoNota: TipoNota
    let fecha: Date
    let modalidad: String        // "Presencial" / "Teleconsulta"
    let subtipo: String
    let area: String
    let doctor: String
    let enfermera: String?
    let signosVitales: SignosVitales?
    let textoNota: String
    let estatus: NotaEstatus

    var fechaFormateada: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: fecha)
    }

    var fechaCorta: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: fecha)
    }
}

// MARK: - Mock Data

extension NotaMedica {
    static let mockList: [NotaMedica] = {
        let calendar = Calendar.current
        let today = Date()
        let pacientes = Paciente.mockList

        return [
            NotaMedica(
                id: "NM-001", paciente: pacientes[0], tipoNota: .notaMedica,
                fecha: calendar.date(byAdding: .day, value: -1, to: today)!,
                modalidad: "Presencial", subtipo: "Consulta de seguimiento", area: "Reproducción Asistida",
                doctor: "Dr. Alejandro Rivas", enfermera: "Enf. Mariana López",
                signosVitales: SignosVitales(peso: 62.5, estatura: 165, imc: 22.9, presionArterial: "118/75", frecuenciaCardiaca: 72, frecuenciaRespiratoria: 16, saturacionO2: 98, temperatura: 36.5),
                textoNota: "Paciente en día 12 del ciclo. Folículos en desarrollo adecuado. Se programa transferencia para la próxima semana.",
                estatus: .completada
            ),
            NotaMedica(
                id: "NM-002", paciente: pacientes[1], tipoNota: .notaSEI,
                fecha: calendar.date(byAdding: .day, value: -1, to: today)!,
                modalidad: "Presencial", subtipo: "Evaluación inicial", area: "Estimulación Ovárica",
                doctor: "Dra. Patricia Vega", enfermera: "Enf. Rosa Martínez",
                signosVitales: SignosVitales(peso: 58.0, estatura: 160, imc: 22.7, presionArterial: "115/70", frecuenciaCardiaca: 68, frecuenciaRespiratoria: 15, saturacionO2: 99, temperatura: 36.3),
                textoNota: "Inicio de protocolo de estimulación ovárica. Hormona FSH en rangos normales. Se indica medicación.",
                estatus: .completada
            ),
            NotaMedica(
                id: "NM-003", paciente: pacientes[2], tipoNota: .notaMedica,
                fecha: calendar.date(byAdding: .day, value: -2, to: today)!,
                modalidad: "Teleconsulta", subtipo: "Seguimiento post-transferencia", area: "Reproducción Asistida",
                doctor: "Dr. Alejandro Rivas", enfermera: nil,
                signosVitales: nil,
                textoNota: "Paciente reporta síntomas normales post-transferencia. Sin sangrado. Se programa beta-HCG para el día 14.",
                estatus: .revisada
            ),
            NotaMedica(
                id: "NM-004", paciente: pacientes[3], tipoNota: .notaComercial,
                fecha: calendar.date(byAdding: .day, value: -2, to: today)!,
                modalidad: "Presencial", subtipo: "Consulta informativa", area: "Comercial",
                doctor: "Dra. Carmen Mendoza", enfermera: nil,
                signosVitales: nil,
                textoNota: "Paciente interesada en programa de donación de óvulos. Se explican opciones y costos. Se agenda cita de valoración.",
                estatus: .completada
            ),
            NotaMedica(
                id: "NM-005", paciente: pacientes[4], tipoNota: .notaCI,
                fecha: calendar.date(byAdding: .day, value: -3, to: today)!,
                modalidad: "Presencial", subtipo: "Consentimiento informado", area: "Reproducción Asistida",
                doctor: "Dr. Alejandro Rivas", enfermera: "Enf. Mariana López",
                signosVitales: SignosVitales(peso: 70.0, estatura: 168, imc: 24.8, presionArterial: "122/78", frecuenciaCardiaca: 75, frecuenciaRespiratoria: 17, saturacionO2: 97, temperatura: 36.6),
                textoNota: "Se firma consentimiento informado para procedimiento de FIV con óvulos propios. Paciente comprende riesgos y beneficios.",
                estatus: .revisada
            ),
            NotaMedica(
                id: "NM-006", paciente: pacientes[5], tipoNota: .notaSM,
                fecha: calendar.date(byAdding: .day, value: -3, to: today)!,
                modalidad: "Presencial", subtipo: "Salud mental", area: "Psicología",
                doctor: "Dra. Patricia Vega", enfermera: nil,
                signosVitales: nil,
                textoNota: "Sesión de apoyo emocional. Paciente presenta ansiedad moderada por resultados pendientes. Se trabaja manejo del estrés.",
                estatus: .completada
            ),
            NotaMedica(
                id: "NM-007", paciente: pacientes[6], tipoNota: .notaMedica,
                fecha: calendar.date(byAdding: .day, value: -4, to: today)!,
                modalidad: "Presencial", subtipo: "Primera consulta", area: "Reproducción Asistida",
                doctor: "Dra. Carmen Mendoza", enfermera: "Enf. Rosa Martínez",
                signosVitales: SignosVitales(peso: 55.0, estatura: 158, imc: 22.0, presionArterial: "110/68", frecuenciaCardiaca: 65, frecuenciaRespiratoria: 14, saturacionO2: 99, temperatura: 36.4),
                textoNota: "Primera consulta de fertilidad. Se solicitan estudios hormonales, ultrasonido y espermograma de pareja.",
                estatus: .completada
            ),
            NotaMedica(
                id: "NM-008", paciente: pacientes[7], tipoNota: .notaSEI,
                fecha: calendar.date(byAdding: .day, value: -4, to: today)!,
                modalidad: "Presencial", subtipo: "Control ecográfico", area: "Estimulación Ovárica",
                doctor: "Dr. Alejandro Rivas", enfermera: "Enf. Mariana López",
                signosVitales: SignosVitales(peso: 60.0, estatura: 162, imc: 22.9, presionArterial: "116/72", frecuenciaCardiaca: 70, frecuenciaRespiratoria: 16, saturacionO2: 98, temperatura: 36.5),
                textoNota: "Ultrasonido de control día 8. Se observan 6 folículos dominantes. Endometrio 9mm trilaminar. Continuar medicación.",
                estatus: .revisada
            ),
            NotaMedica(
                id: "NM-009", paciente: pacientes[8], tipoNota: .notaMedica,
                fecha: calendar.date(byAdding: .day, value: -5, to: today)!,
                modalidad: "Teleconsulta", subtipo: "Resultados de laboratorio", area: "Reproducción Asistida",
                doctor: "Dra. Patricia Vega", enfermera: nil,
                signosVitales: nil,
                textoNota: "Revisión de resultados hormonales. AMH: 2.8 ng/mL, FSH: 7.2 mUI/mL. Reserva ovárica adecuada para edad.",
                estatus: .completada
            ),
            NotaMedica(
                id: "NM-010", paciente: pacientes[9], tipoNota: .notaComercial,
                fecha: calendar.date(byAdding: .day, value: -5, to: today)!,
                modalidad: "Presencial", subtipo: "Plan de tratamiento", area: "Comercial",
                doctor: "Dra. Carmen Mendoza", enfermera: nil,
                signosVitales: nil,
                textoNota: "Se presenta plan de tratamiento FIV con seguro. Paciente acepta y firma contrato. Inicio programado para siguiente ciclo.",
                estatus: .completada
            ),
            NotaMedica(
                id: "NM-011", paciente: pacientes[0], tipoNota: .notaMedica,
                fecha: calendar.date(byAdding: .day, value: -7, to: today)!,
                modalidad: "Presencial", subtipo: "Punción ovárica", area: "Quirófano",
                doctor: "Dr. Alejandro Rivas", enfermera: "Enf. Mariana López",
                signosVitales: SignosVitales(peso: 62.5, estatura: 165, imc: 22.9, presionArterial: "120/78", frecuenciaCardiaca: 80, frecuenciaRespiratoria: 18, saturacionO2: 97, temperatura: 36.7),
                textoNota: "Punción ovárica exitosa. Se obtienen 12 ovocitos. Paciente tolera procedimiento sin complicaciones.",
                estatus: .revisada
            ),
            NotaMedica(
                id: "NM-012", paciente: pacientes[1], tipoNota: .notaSEI,
                fecha: calendar.date(byAdding: .day, value: -8, to: today)!,
                modalidad: "Presencial", subtipo: "Evaluación pre-quirúrgica", area: "Estimulación Ovárica",
                doctor: "Dra. Patricia Vega", enfermera: "Enf. Rosa Martínez",
                signosVitales: SignosVitales(peso: 58.0, estatura: 160, imc: 22.7, presionArterial: "112/70", frecuenciaCardiaca: 66, frecuenciaRespiratoria: 15, saturacionO2: 99, temperatura: 36.2),
                textoNota: "Evaluación pre-quirúrgica completa. Estudios de laboratorio dentro de parámetros normales. Apta para procedimiento.",
                estatus: .revisada
            ),
            NotaMedica(
                id: "NM-013", paciente: pacientes[3], tipoNota: .notaMedica,
                fecha: today,
                modalidad: "Presencial", subtipo: "Consulta de seguimiento", area: "Reproducción Asistida",
                doctor: "Dra. Carmen Mendoza", enfermera: "Enf. Mariana López",
                signosVitales: nil,
                textoNota: "",
                estatus: .pendiente
            ),
            NotaMedica(
                id: "NM-014", paciente: pacientes[5], tipoNota: .notaSEI,
                fecha: today,
                modalidad: "Presencial", subtipo: "Control ecográfico", area: "Estimulación Ovárica",
                doctor: "Dra. Patricia Vega", enfermera: nil,
                signosVitales: nil,
                textoNota: "",
                estatus: .pendiente
            ),
            NotaMedica(
                id: "NM-015", paciente: pacientes[8], tipoNota: .notaMedica,
                fecha: today,
                modalidad: "Teleconsulta", subtipo: "Seguimiento", area: "Reproducción Asistida",
                doctor: "Dra. Patricia Vega", enfermera: nil,
                signosVitales: nil,
                textoNota: "",
                estatus: .pendiente
            ),
            NotaMedica(
                id: "NM-016", paciente: pacientes[2], tipoNota: .notaCI,
                fecha: calendar.date(byAdding: .day, value: -10, to: today)!,
                modalidad: "Presencial", subtipo: "Consentimiento informado", area: "Reproducción Asistida",
                doctor: "Dr. Alejandro Rivas", enfermera: "Enf. Rosa Martínez",
                signosVitales: SignosVitales(peso: 65.0, estatura: 170, imc: 22.5, presionArterial: "118/74", frecuenciaCardiaca: 71, frecuenciaRespiratoria: 16, saturacionO2: 98, temperatura: 36.4),
                textoNota: "Firma de consentimiento para criopreservación de embriones. Paciente informada sobre tasas de supervivencia y costos de almacenamiento.",
                estatus: .revisada
            ),
            NotaMedica(
                id: "NM-017", paciente: pacientes[7], tipoNota: .notaSM,
                fecha: calendar.date(byAdding: .day, value: -6, to: today)!,
                modalidad: "Teleconsulta", subtipo: "Apoyo emocional", area: "Psicología",
                doctor: "Dra. Carmen Mendoza", enfermera: nil,
                signosVitales: nil,
                textoNota: "Sesión de orientación para pareja. Se trabajan expectativas del tratamiento y comunicación en pareja.",
                estatus: .completada
            ),
            NotaMedica(
                id: "NM-018", paciente: pacientes[4], tipoNota: .notaMedica,
                fecha: calendar.date(byAdding: .day, value: -9, to: today)!,
                modalidad: "Presencial", subtipo: "Transferencia embrionaria", area: "Quirófano",
                doctor: "Dr. Alejandro Rivas", enfermera: "Enf. Mariana López",
                signosVitales: SignosVitales(peso: 70.0, estatura: 168, imc: 24.8, presionArterial: "120/76", frecuenciaCardiaca: 74, frecuenciaRespiratoria: 16, saturacionO2: 98, temperatura: 36.5),
                textoNota: "Transferencia de 2 embriones en día 5 (blastocistos). Procedimiento sin complicaciones. Reposo relativo indicado.",
                estatus: .revisada
            )
        ]
    }()

    static let mock = mockList[0]
}
