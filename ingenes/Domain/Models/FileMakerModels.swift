// FileMakerModels.swift
// Ingenes
//
// FileMaker API response wrapper models

import Foundation

// MARK: - Generic Response Wrappers

struct FileMakerResponse<T: Codable>: Codable {
    let response: T
    let messages: [FileMakerMessage]?
}

struct FileMakerMessage: Codable {
    let code: String
    let message: String
}

struct FileMakerRecordsResponse<T: Codable>: Codable {
    let response: FileMakerDataResponse<T>
    let messages: [FileMakerMessage]?
}

struct FileMakerDataResponse<T: Codable>: Codable {
    let data: [FileMakerRecord<T>]
    let dataInfo: FileMakerDataInfo?
}

struct FileMakerRecord<T: Codable>: Codable {
    let fieldData: T
    let recordId: String
    let modId: String?
    let portalData: EmptyPortalData?

    enum CodingKeys: String, CodingKey {
        case fieldData
        case recordId
        case modId
        case portalData
    }
}

// Portal data is typically an empty object {} in responses
struct EmptyPortalData: Codable {}

// Helper for decoding portal data which can have various structures
struct AnyDecodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        }
    }
}

struct FileMakerDataInfo: Codable {
    let database: String?
    let layout: String?
    let table: String?
    let totalRecordCount: Int?
    let foundCount: Int?
    let returnedCount: Int?
}

// MARK: - Token Response

struct TokenResponse: Codable {
    let response: TokenData
    let messages: [FileMakerMessage]?
}

struct TokenData: Codable {
    let token: String
}

// MARK: - Login Response

struct LocationFieldData: Codable {
    let id: String
    let name: String
    let storeName: String
    let status: String
    let customerId: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case storeName = "StoreName"
        case status = "Status"
        case customerId = "CustomerId"
    }

    func toLocation() -> Location {
        Location(
            id: id,
            name: name,
            storeName: storeName,
            status: status,
            customerId: customerId
        )
    }
}

// MARK: - FileMaker User Field Data (@Usuarios layout)

struct FileMakerUserFieldData: Codable {
    let nombre: String?
    let email: String?
    let estatus: String?
    let tipoCuenta: String?
    let usuario: String?
    let pk: String?
    let sucursal: String?
    let idSucursal: String?
    let cuentaNum: String?
    let fechaCreacion: String?

    enum CodingKeys: String, CodingKey {
        case nombre = "Usu_Nombre"
        case email = "Usu_Mail"
        case estatus = "Usu_Estatus"
        case tipoCuenta = "Usu_TipoCuenta"
        case usuario = "Usu_Usuario"
        case pk = "Usu_PK"
        case sucursal = "Usu_Sucursal"
        case idSucursal = "Usu_IDSucursal"
        case cuentaNum = "Usu_Cuenta_Num"
        case fechaCreacion = "Usu_FeHoCreacion"
    }

    func toUser(recordId: String) -> User {
        // Parse the full name into first and last name
        let fullName = nombre ?? ""
        let nameParts = fullName.components(separatedBy: " ")
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.dropFirst().joined(separator: " ")

        return User(
            id: cuentaNum ?? recordId,
            firstName: firstName,
            lastName: lastName,
            email: email ?? "",
            companyId: idSucursal ?? "",
            userType: tipoCuenta ?? "Usuario",
            username: usuario ?? "",
            phone: nil,
            recordId: recordId
        )
    }
}


// MARK: - Find Request Body

struct FileMakerFindRequest: Encodable {
    let query: [[String: String]]

    init(query: [String: String]) {
        self.query = [query]
    }

    init(queries: [[String: String]]) {
        self.query = queries
    }
}

// MARK: - Create Record Request Body

struct FileMakerCreateRequest: Encodable {
    let fieldData: [String: Any]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Convert fieldData to a serializable format
        let jsonData = try JSONSerialization.data(withJSONObject: fieldData)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        try container.encode(jsonObject.mapValues { AnyCodable($0) }, forKey: .fieldData)
    }

    enum CodingKeys: String, CodingKey {
        case fieldData
    }
}

// MARK: - Helper for encoding Any values

struct AnyCodable: Encodable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        default:
            try container.encode(String(describing: value))
        }
    }
}
