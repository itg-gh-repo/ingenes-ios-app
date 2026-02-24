// Paciente.swift
// Ingenes
//
// Patient model for fertility clinic

import Foundation

struct Paciente: Identifiable, Equatable {
    let id: String
    let nhc: String          // Número de Historia Clínica
    let nombre: String
    let apellidos: String
    let edad: Int
    let fechaPrimeraVisita: Date
    let doctorAsignado: String
    let parejaNombre: String?
    let genero: Genero

    enum Genero: String, CaseIterable {
        case femenino = "Femenino"
        case masculino = "Masculino"
    }

    var nombreCompleto: String {
        "\(nombre) \(apellidos)"
    }

    var edadTexto: String {
        "\(edad) años"
    }

    var iniciales: String {
        let first = nombre.prefix(1).uppercased()
        let last = apellidos.prefix(1).uppercased()
        return first + last
    }
}

// MARK: - Mock Data

extension Paciente {
    static let mockList: [Paciente] = {
        let calendar = Calendar.current
        let today = Date()
        return [
            Paciente(
                id: "PAC-001", nhc: "NHC-20240001",
                nombre: "María", apellidos: "García López",
                edad: 34, fechaPrimeraVisita: calendar.date(byAdding: .month, value: -8, to: today)!,
                doctorAsignado: "Dr. Alejandro Rivas", parejaNombre: "Carlos García", genero: .femenino
            ),
            Paciente(
                id: "PAC-002", nhc: "NHC-20240015",
                nombre: "Ana", apellidos: "Martínez Ruiz",
                edad: 31, fechaPrimeraVisita: calendar.date(byAdding: .month, value: -6, to: today)!,
                doctorAsignado: "Dra. Patricia Vega", parejaNombre: "Luis Martínez", genero: .femenino
            ),
            Paciente(
                id: "PAC-003", nhc: "NHC-20240023",
                nombre: "Laura", apellidos: "Hernández Torres",
                edad: 38, fechaPrimeraVisita: calendar.date(byAdding: .month, value: -12, to: today)!,
                doctorAsignado: "Dr. Alejandro Rivas", parejaNombre: "Roberto Hernández", genero: .femenino
            ),
            Paciente(
                id: "PAC-004", nhc: "NHC-20240031",
                nombre: "Sofía", apellidos: "Ramírez Flores",
                edad: 29, fechaPrimeraVisita: calendar.date(byAdding: .month, value: -3, to: today)!,
                doctorAsignado: "Dra. Carmen Mendoza", parejaNombre: "Diego Ramírez", genero: .femenino
            ),
            Paciente(
                id: "PAC-005", nhc: "NHC-20240042",
                nombre: "Isabella", apellidos: "López Moreno",
                edad: 36, fechaPrimeraVisita: calendar.date(byAdding: .month, value: -5, to: today)!,
                doctorAsignado: "Dr. Alejandro Rivas", parejaNombre: nil, genero: .femenino
            ),
            Paciente(
                id: "PAC-006", nhc: "NHC-20240055",
                nombre: "Valentina", apellidos: "Díaz Castillo",
                edad: 42, fechaPrimeraVisita: calendar.date(byAdding: .month, value: -14, to: today)!,
                doctorAsignado: "Dra. Patricia Vega", parejaNombre: "Fernando Díaz", genero: .femenino
            ),
            Paciente(
                id: "PAC-007", nhc: "NHC-20240068",
                nombre: "Camila", apellidos: "Sánchez Ortega",
                edad: 33, fechaPrimeraVisita: calendar.date(byAdding: .month, value: -2, to: today)!,
                doctorAsignado: "Dra. Carmen Mendoza", parejaNombre: "Andrés Sánchez", genero: .femenino
            ),
            Paciente(
                id: "PAC-008", nhc: "NHC-20240076",
                nombre: "Regina", apellidos: "Torres Aguilar",
                edad: 28, fechaPrimeraVisita: calendar.date(byAdding: .month, value: -1, to: today)!,
                doctorAsignado: "Dr. Alejandro Rivas", parejaNombre: "Miguel Torres", genero: .femenino
            ),
            Paciente(
                id: "PAC-009", nhc: "NHC-20240089",
                nombre: "Fernanda", apellidos: "Cruz Vargas",
                edad: 37, fechaPrimeraVisita: calendar.date(byAdding: .month, value: -10, to: today)!,
                doctorAsignado: "Dra. Patricia Vega", parejaNombre: "Javier Cruz", genero: .femenino
            ),
            Paciente(
                id: "PAC-010", nhc: "NHC-20240095",
                nombre: "Daniela", apellidos: "Reyes Navarro",
                edad: 40, fechaPrimeraVisita: calendar.date(byAdding: .month, value: -7, to: today)!,
                doctorAsignado: "Dra. Carmen Mendoza", parejaNombre: "Pablo Reyes", genero: .femenino
            )
        ]
    }()

    static let mock = mockList[0]
}
