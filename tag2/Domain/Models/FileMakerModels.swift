// FileMakerModels.swift
// TAG2
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
    let id: Int?
    let nombreCompleto: String?
    let email: String?
    let idEmpresa: String?
    let idUsuario: Int?
    let tipo: String?
    let usuario: String?
    let celular: String?
    let password: String?
    let registros: Int?
    let fechaRegistro: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nombreCompleto
        case email = "Email"
        case idEmpresa
        case idUsuario
        case tipo
        case usuario
        case celular
        case password
        case registros
        case fechaRegistro
    }

    func toUser(recordId: String) -> User {
        // Parse the full name into first and last name
        let fullName = nombreCompleto ?? ""
        let nameParts = fullName.components(separatedBy: " ")
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.dropFirst().joined(separator: " ")

        // Convert idUsuario Int to String for User.id
        let odUserId = idUsuario.map { String($0) } ?? recordId

        return User(
            id: odUserId,
            firstName: firstName,
            lastName: lastName,
            email: email ?? "",
            companyId: idEmpresa ?? "",
            userType: tipo ?? "Usuario",
            username: usuario ?? "",
            phone: celular,
            recordId: recordId
        )
    }
}

// MARK: - Award Field Data

struct AwardFieldData: Codable {
    let id: String
    let name: String
    let description: String
    let programType: String
    let startDate: String?
    let endDate: String?
    let isActive: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case description = "Description"
        case programType = "ProgramType"
        case startDate = "StartDate"
        case endDate = "EndDate"
        case isActive = "IsActive"
    }

    func toAward() -> Award {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"

        return Award(
            id: id,
            name: name,
            description: description,
            programType: ProgramType(rawValue: programType) ?? .monthly,
            startDate: startDate.flatMap { dateFormatter.date(from: $0) },
            endDate: endDate.flatMap { dateFormatter.date(from: $0) },
            isActive: isActive == "1" || isActive.lowercased() == "true",
            requiredFields: nil
        )
    }
}

// MARK: - Winner Field Data

struct WinnerFieldData: Codable {
    let id: String
    let name: String
    let title: String
    let month: String
    let year: String
    let awardId: String
    let awardName: String
    let submittedDate: String
    let trackingNumber: String?
    let dateShipped: String?
    let workOrderStatus: String
    let nameplateSize: String?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case title = "Title"
        case month = "Month"
        case year = "Year"
        case awardId = "AwardId"
        case awardName = "AwardName"
        case submittedDate = "SubmittedDate"
        case trackingNumber = "TrackingNumber"
        case dateShipped = "DateShipped"
        case workOrderStatus = "WorkOrderStatus"
        case nameplateSize = "NameplateSize"
        case reason = "Reason"
    }

    func toWinner() -> Winner {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"

        let isoFormatter = ISO8601DateFormatter()

        return Winner(
            id: id,
            name: name,
            title: title,
            month: Int(month) ?? 1,
            year: Int(year) ?? Calendar.current.component(.year, from: Date()),
            awardId: awardId,
            awardName: awardName,
            submittedDate: isoFormatter.date(from: submittedDate) ?? dateFormatter.date(from: submittedDate) ?? Date(),
            trackingNumber: trackingNumber?.isEmpty == true ? nil : trackingNumber,
            dateShipped: dateShipped.flatMap { dateFormatter.date(from: $0) },
            workOrderStatus: workOrderStatus,
            nameplateSize: nameplateSize?.isEmpty == true ? nil : nameplateSize,
            reason: reason?.isEmpty == true ? nil : reason
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

// MARK: - Proyecto Field Data (@Projects layout)

struct ProyectoFieldData: Codable {
    let descripcion: String
    let estatus: String
    let fechaRegistro: String
    let idProyecto: Int
    let socioNegocio: String
    let tipoProyecto: String
    let anio: Int
    let pk: String
    let ubicacion: String
    let fechaInicio: String
    let fechaFinal: String
    let idEmpresa: Int
    let pkSocioNegocio: String
    let recId: Int
    let idSN: Int
    let responsable: String
    let pkResponsable: String
    let presupuesto: Double

    enum CodingKeys: String, CodingKey {
        case descripcion
        case estatus
        case fechaRegistro
        case idProyecto
        case socioNegocio
        case tipoProyecto
        case anio
        case pk
        case ubicacion
        case fechaInicio
        case fechaFinal
        case idEmpresa
        case pkSocioNegocio = "pk_socioNegocio"
        case recId
        case idSN
        case responsable
        case pkResponsable = "pk_responsable"
        case presupuesto
    }

    // Custom decoder to handle potential type mismatches or missing values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        descripcion = (try? container.decode(String.self, forKey: .descripcion)) ?? ""
        estatus = (try? container.decode(String.self, forKey: .estatus)) ?? ""
        fechaRegistro = (try? container.decode(String.self, forKey: .fechaRegistro)) ?? ""
        socioNegocio = (try? container.decode(String.self, forKey: .socioNegocio)) ?? ""
        tipoProyecto = (try? container.decode(String.self, forKey: .tipoProyecto)) ?? ""
        pk = (try? container.decode(String.self, forKey: .pk)) ?? ""
        ubicacion = (try? container.decode(String.self, forKey: .ubicacion)) ?? ""
        fechaInicio = (try? container.decode(String.self, forKey: .fechaInicio)) ?? ""
        fechaFinal = (try? container.decode(String.self, forKey: .fechaFinal)) ?? ""
        pkSocioNegocio = (try? container.decode(String.self, forKey: .pkSocioNegocio)) ?? ""
        responsable = (try? container.decode(String.self, forKey: .responsable)) ?? ""
        pkResponsable = (try? container.decode(String.self, forKey: .pkResponsable)) ?? ""

        // Handle Int fields that might come as Int or String
        if let intValue = try? container.decode(Int.self, forKey: .idProyecto) {
            idProyecto = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .idProyecto),
                  let intValue = Int(stringValue) {
            idProyecto = intValue
        } else {
            idProyecto = 0
        }

        if let intValue = try? container.decode(Int.self, forKey: .anio) {
            anio = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .anio),
                  let intValue = Int(stringValue) {
            anio = intValue
        } else {
            anio = 0
        }

        if let intValue = try? container.decode(Int.self, forKey: .idEmpresa) {
            idEmpresa = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .idEmpresa),
                  let intValue = Int(stringValue) {
            idEmpresa = intValue
        } else {
            idEmpresa = 0
        }

        if let intValue = try? container.decode(Int.self, forKey: .recId) {
            recId = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .recId),
                  let intValue = Int(stringValue) {
            recId = intValue
        } else {
            recId = 0
        }

        if let intValue = try? container.decode(Int.self, forKey: .idSN) {
            idSN = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .idSN),
                  let intValue = Int(stringValue) {
            idSN = intValue
        } else {
            idSN = 0
        }

        // Handle presupuesto (Double) that might come as Double, Int, or String
        if let doubleValue = try? container.decode(Double.self, forKey: .presupuesto) {
            presupuesto = doubleValue
        } else if let intValue = try? container.decode(Int.self, forKey: .presupuesto) {
            presupuesto = Double(intValue)
        } else if let stringValue = try? container.decode(String.self, forKey: .presupuesto),
                  let doubleValue = Double(stringValue) {
            presupuesto = doubleValue
        } else {
            presupuesto = 0
        }
    }
}

// MARK: - Proyecto Find Request (with limit and sort)

struct ProyectoSortOrder: Encodable {
    let fieldName: String
    let sortOrder: String
}

struct ProyectoFindRequest: Encodable {
    let query: [[String: String]]
    let sort: [ProyectoSortOrder]?
    let limit: Int

    init(query: [String: String], sort: [ProyectoSortOrder]? = nil, limit: Int = 1000) {
        self.query = [query]
        self.sort = sort
        self.limit = limit
    }
}

// MARK: - Pedido Field Data (@Pedidos layout)

struct PedidoFieldData: Codable {
    let id: Int
    let idPedido: Int
    let idPedido_: Int      // The pedido number within the project (used for display ID)
    let idProyecto: Int     // The project ID (used for display ID)
    let idEmpresa: Int
    let fecha: String
    let fechaCreacion: String
    let estatus: String
    let concepto: String
    let tipoPedido: String
    let clase: String
    let condicionesPago: String
    let moneda: String
    let observaciones: String
    let idUsuario: String
    let usuarioS: String
    let socioNegocioProveedor: String
    let socioNegocioProyecto: String
    let proyectoDescripcion: String
    let proyectoUbicacion: String
    let totalN: Double
    let pagado: Double
    let adeudo: Double
    let idSNProveedor: Int
    let idSNProyecto: Int
    let idSNBeneficiario: Int
    let recordId: String
    let cotizacion: String      // URL to the quotation PDF
    let facturaPDF: String      // URL to the invoice PDF
    let facturaXML: String      // URL to the invoice XML (CFDI)
    let comprobacion: String    // URL to the verification/proof PDF

    enum CodingKeys: String, CodingKey {
        case id
        case idPedido
        case idPedido_ = "idPedido_"
        case idProyecto
        case idEmpresa
        case fecha
        case fechaCreacion = "fechaCREACION"
        case estatus = "Estatus"
        case concepto
        case tipoPedido
        case clase
        case condicionesPago = "Condiciones Pago"
        case moneda = "Moneda"
        case observaciones = "Observaciones"
        case idUsuario
        case usuarioS = "UsuarioS"
        case socioNegocioProveedor
        case socioNegocioProyecto
        case proyectoDescripcion = "Proyecto Descripcion"
        case proyectoUbicacion = "Proyecto Ubicacion"
        case totalN = "total_n"
        case pagado
        case adeudo
        case idSNProveedor
        case idSNProyecto
        case idSNBeneficiario
        case recordId = "ID_record"
        case cotizacion
        case facturaPDF = "Factura PDF"
        case facturaXML = "Factura XML"
        case comprobacion
    }

    // Custom decoder to handle potential type mismatches or missing values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // String fields with defaults
        fecha = (try? container.decode(String.self, forKey: .fecha)) ?? ""
        fechaCreacion = (try? container.decode(String.self, forKey: .fechaCreacion)) ?? ""
        estatus = (try? container.decode(String.self, forKey: .estatus)) ?? ""
        concepto = (try? container.decode(String.self, forKey: .concepto)) ?? ""
        tipoPedido = (try? container.decode(String.self, forKey: .tipoPedido)) ?? ""
        clase = (try? container.decode(String.self, forKey: .clase)) ?? ""
        condicionesPago = (try? container.decode(String.self, forKey: .condicionesPago)) ?? ""
        moneda = (try? container.decode(String.self, forKey: .moneda)) ?? "MXN"
        observaciones = (try? container.decode(String.self, forKey: .observaciones)) ?? ""
        idUsuario = (try? container.decode(String.self, forKey: .idUsuario)) ?? ""
        usuarioS = (try? container.decode(String.self, forKey: .usuarioS)) ?? ""
        socioNegocioProveedor = (try? container.decode(String.self, forKey: .socioNegocioProveedor)) ?? ""
        socioNegocioProyecto = (try? container.decode(String.self, forKey: .socioNegocioProyecto)) ?? ""
        proyectoDescripcion = (try? container.decode(String.self, forKey: .proyectoDescripcion)) ?? ""
        proyectoUbicacion = (try? container.decode(String.self, forKey: .proyectoUbicacion)) ?? ""
        recordId = (try? container.decode(String.self, forKey: .recordId)) ?? ""
        cotizacion = (try? container.decode(String.self, forKey: .cotizacion)) ?? ""
        facturaPDF = (try? container.decode(String.self, forKey: .facturaPDF)) ?? ""
        facturaXML = (try? container.decode(String.self, forKey: .facturaXML)) ?? ""
        comprobacion = (try? container.decode(String.self, forKey: .comprobacion)) ?? ""

        // Handle Int fields that might come as Int or String
        if let intValue = try? container.decode(Int.self, forKey: .id) {
            id = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .id),
                  let intValue = Int(stringValue) {
            id = intValue
        } else {
            id = 0
        }

        if let intValue = try? container.decode(Int.self, forKey: .idPedido) {
            idPedido = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .idPedido),
                  let intValue = Int(stringValue) {
            idPedido = intValue
        } else {
            idPedido = 0
        }

        // idPedido_ - the pedido number within the project
        if let intValue = try? container.decode(Int.self, forKey: .idPedido_) {
            idPedido_ = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .idPedido_),
                  let intValue = Int(stringValue) {
            idPedido_ = intValue
        } else {
            idPedido_ = 0
        }

        // idProyecto - the project ID
        if let intValue = try? container.decode(Int.self, forKey: .idProyecto) {
            idProyecto = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .idProyecto),
                  let intValue = Int(stringValue) {
            idProyecto = intValue
        } else {
            idProyecto = 0
        }

        if let intValue = try? container.decode(Int.self, forKey: .idEmpresa) {
            idEmpresa = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .idEmpresa),
                  let intValue = Int(stringValue) {
            idEmpresa = intValue
        } else {
            idEmpresa = 0
        }

        if let intValue = try? container.decode(Int.self, forKey: .idSNProveedor) {
            idSNProveedor = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .idSNProveedor),
                  let intValue = Int(stringValue) {
            idSNProveedor = intValue
        } else {
            idSNProveedor = 0
        }

        if let intValue = try? container.decode(Int.self, forKey: .idSNProyecto) {
            idSNProyecto = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .idSNProyecto),
                  let intValue = Int(stringValue) {
            idSNProyecto = intValue
        } else {
            idSNProyecto = 0
        }

        if let intValue = try? container.decode(Int.self, forKey: .idSNBeneficiario) {
            idSNBeneficiario = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .idSNBeneficiario),
                  let intValue = Int(stringValue) {
            idSNBeneficiario = intValue
        } else {
            idSNBeneficiario = 0
        }

        // Handle Double fields that might come as Double, Int, String, or "?"
        totalN = PedidoFieldData.parseDouble(from: container, forKey: .totalN)
        pagado = PedidoFieldData.parseDouble(from: container, forKey: .pagado)
        adeudo = PedidoFieldData.parseDouble(from: container, forKey: .adeudo)
    }

    private static func parseDouble(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Double {
        if let doubleValue = try? container.decode(Double.self, forKey: key) {
            return doubleValue
        } else if let intValue = try? container.decode(Int.self, forKey: key) {
            return Double(intValue)
        } else if let stringValue = try? container.decode(String.self, forKey: key) {
            // Handle "?" or empty strings
            if stringValue == "?" || stringValue.isEmpty {
                return 0
            }
            return Double(stringValue) ?? 0
        }
        return 0
    }
}

// MARK: - Pedido Find Request (with limit and sort)

struct PedidoFindRequest: Encodable {
    let query: [[String: String]]
    let sort: [ProyectoSortOrder]?
    let limit: Int

    init(query: [String: String], sort: [ProyectoSortOrder]? = nil, limit: Int = 150) {
        self.query = [query]
        self.sort = sort
        self.limit = limit
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
