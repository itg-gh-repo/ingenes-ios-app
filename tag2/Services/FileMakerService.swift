// FileMakerService.swift
// TAG2
//
// Actor-based FileMaker API service with token management
// Credentials are fetched securely from AWS Secrets Manager

import Foundation

actor FileMakerService {
    static let shared = FileMakerService()

    private var authToken: String?
    private var tokenExpiry: Date?
    private var cachedCredentials: FileMakerCredentials?

    private init() {}

    // MARK: - Get Credentials

    private func getCredentials() async throws -> FileMakerCredentials {
        if let cached = cachedCredentials {
            return cached
        }

        let credentials = try await SecretsManagerService.shared.getFileMakerCredentials()
        cachedCredentials = credentials
        return credentials
    }

    // MARK: - Token Management

    func getToken() async throws -> String {
        // Check cached token
        if let token = authToken, let expiry = tokenExpiry, expiry > Date() {
            logInfo("Using cached FileMaker token (expires: \(expiry))")
            return token
        }

        // Check Keychain for existing token
        if let storedToken = KeychainManager.shared.get(.fileMakerToken),
           let storedExpiry = KeychainManager.shared.getTokenExpiry(.fileMakerTokenExpiry),
           storedExpiry > Date() {
            logInfo("Using Keychain FileMaker token (expires: \(storedExpiry))")
            self.authToken = storedToken
            self.tokenExpiry = storedExpiry
            return storedToken
        }

        logInfo("No valid token found, requesting new FileMaker session...")

        // Clear any expired tokens from Keychain
        KeychainManager.shared.delete(.fileMakerToken)
        KeychainManager.shared.delete(.fileMakerTokenExpiry)

        // Get credentials from Secrets Manager
        let credentials = try await getCredentials()

        logInfo("FileMaker credentials loaded - baseUrl: \(credentials.baseUrl), username: \(credentials.username)")

        // Request new token
        guard let url = URL(string: "\(credentials.baseUrl)/sessions") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(credentials.base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)

        logInfo("FileMaker session URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        logInfo("FileMaker session response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            logError("FileMaker session failed with status \(httpResponse.statusCode): \(responseBody)")
            // Clear all cached credentials since they might be invalid
            cachedCredentials = nil
            await SecretsManagerService.shared.clearCache()
            throw FileMakerError.authenticationFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        let newToken = tokenResponse.response.token
        let newExpiry = Date().addingTimeInterval(600) // 10 minutes

        // Cache token
        self.authToken = newToken
        self.tokenExpiry = newExpiry

        // Store in Keychain
        try? KeychainManager.shared.store(newToken, for: .fileMakerToken)
        try? KeychainManager.shared.storeTokenExpiry(newExpiry, for: .fileMakerTokenExpiry)

        return newToken
    }

    func clearToken() {
        authToken = nil
        tokenExpiry = nil
        cachedCredentials = nil
        KeychainManager.shared.delete(.fileMakerToken)
        KeychainManager.shared.delete(.fileMakerTokenExpiry)
    }

    // MARK: - Get Base URL

    private func getBaseUrl() async throws -> String {
        let credentials = try await getCredentials()
        return credentials.baseUrl
    }

    // MARK: - User Validation

    /// Validates a user in FileMaker database after Cognito authentication
    /// - Parameters:
    ///   - email: User's email address
    ///   - companyId: Company ID to validate against
    /// - Returns: User data from FileMaker if found
    func validateUser(email: String, companyId: String) async throws -> User {
        logInfo("FileMaker validateUser called - email: \(email), companyId: \(companyId)")

        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        guard let url = URL(string: "\(baseUrl)/layouts/@Usuarios/_find") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Query to find user by email only
        // FileMaker exact match syntax: ==value (no quotes around value)
        // NOTE: Temporarily disabled companyId filter for debugging
        let queryParams: [String: String] = [
            "Email": "==\(email)"
        ]

        // TODO: Re-enable companyId filter after testing
        // if !companyId.isEmpty {
        //     queryParams["idEmpresa"] = "==\(companyId)"
        // }

        let findRequest = FileMakerFindRequest(query: queryParams)

        request.httpBody = try JSONEncoder().encode(findRequest)

        logInfo("FileMaker URL: \(url.absoluteString)")
        logInfo("FileMaker request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        logInfo("FileMaker response status: \(httpResponse.statusCode)")
        let responseBody = String(data: data, encoding: .utf8) ?? ""
        logInfo("FileMaker response body: \(responseBody)")

        if httpResponse.statusCode == 401 {
            clearToken()
            throw APIError.unauthorized
        }

        // FileMaker returns 400 with error code 401 when no records found via _find
        // Also can return 500 for other errors
        if httpResponse.statusCode != 200 {
            // Try to parse FileMaker error
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let messages = json["messages"] as? [[String: Any]],
               let firstMessage = messages.first,
               let code = firstMessage["code"] as? String {
                logError("FileMaker error code: \(code), message: \(firstMessage["message"] ?? "")")
                // Code 401 = No records match the request
                if code == "401" {
                    throw FileMakerError.recordNotFound
                }
            }
            logError("FileMaker user validation failed with status: \(httpResponse.statusCode)")
            throw FileMakerError.recordNotFound
        }

        do {
            let recordsResponse = try JSONDecoder().decode(
                FileMakerRecordsResponse<FileMakerUserFieldData>.self,
                from: data
            )

            guard let firstRecord = recordsResponse.response.data.first else {
                logError("FileMaker: No records in response data array")
                throw FileMakerError.recordNotFound
            }

            let user = firstRecord.fieldData.toUser(recordId: firstRecord.recordId)

            logInfo("User validated in FileMaker: \(user.fullName), type: \(user.userType), email: \(user.email)")

            return user
        } catch let decodingError as DecodingError {
            logError("FileMaker JSON decoding error: \(decodingError)")
            logError("Raw response for debugging: \(responseBody)")
            throw FileMakerError.invalidResponse("Error al procesar respuesta del servidor")
        } catch {
            logError("FileMaker unexpected error: \(error)")
            throw error
        }
    }

    func passwordRecovery(email: String) async throws -> Bool {
        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        guard let url = URL(string: "\(baseUrl)/layouts/_webappSalesContacts/script/webapp_sendPassword") else {
            throw APIError.invalidURL
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "script.param", value: email)
        ]

        guard let requestURL = components.url else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        return (200...299).contains(httpResponse.statusCode)
    }

    // MARK: - Winners

    func getMonthlyWinners(customerId: String) async throws -> [Winner] {
        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        guard let url = URL(string: "\(baseUrl)/layouts/_webapp_WO_Names/_find") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let findRequest = FileMakerFindRequest(query: [
            "CustomerId": customerId
        ])

        request.httpBody = try JSONEncoder().encode(findRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            clearToken()
            throw APIError.unauthorized
        }

        // FileMaker returns 401 when no records found via _find
        if httpResponse.statusCode == 401 {
            return []
        }

        guard httpResponse.statusCode == 200 else {
            return []
        }

        let recordsResponse = try JSONDecoder().decode(
            FileMakerRecordsResponse<WinnerFieldData>.self,
            from: data
        )

        return recordsResponse.response.data.map { $0.fieldData.toWinner() }
    }

    // MARK: - Awards

    func getActiveAwardTitles(customerId: String) async throws -> [Award] {
        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        guard let url = URL(string: "\(baseUrl)/layouts/_webappCM_live/_find") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let findRequest = FileMakerFindRequest(query: [
            "CustomerId": customerId,
            "IsActive": "1"
        ])

        request.httpBody = try JSONEncoder().encode(findRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            clearToken()
            throw APIError.unauthorized
        }

        guard httpResponse.statusCode == 200 else {
            return []
        }

        let recordsResponse = try JSONDecoder().decode(
            FileMakerRecordsResponse<AwardFieldData>.self,
            from: data
        )

        return recordsResponse.response.data.map { $0.fieldData.toAward() }
    }

    // MARK: - Submit Winner

    func submitWinner(_ submission: WinnerSubmission) async throws -> Bool {
        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        // Step 1: Create record in API_inbox
        guard let inboxUrl = URL(string: "\(baseUrl)/layouts/API_inbox/records") else {
            throw APIError.invalidURL
        }

        var inboxRequest = URLRequest(url: inboxUrl)
        inboxRequest.httpMethod = "POST"
        inboxRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        inboxRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prepare payload
        let payload: [String: Any] = [
            "fieldData": submission.fieldData
        ]

        inboxRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, inboxResponse) = try await URLSession.shared.data(for: inboxRequest)

        guard let inboxHttpResponse = inboxResponse as? HTTPURLResponse,
              (200...299).contains(inboxHttpResponse.statusCode) else {
            throw FileMakerError.submissionFailed
        }

        // Step 2: Run the ingestion script
        guard let scriptUrl = URL(string: "\(baseUrl)/layouts/API_inbox/script/API_Inbox_Ingestion") else {
            throw APIError.invalidURL
        }

        var scriptRequest = URLRequest(url: scriptUrl)
        scriptRequest.httpMethod = "GET"
        scriptRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, scriptResponse) = try await URLSession.shared.data(for: scriptRequest)

        guard let scriptHttpResponse = scriptResponse as? HTTPURLResponse,
              (200...299).contains(scriptHttpResponse.statusCode) else {
            throw FileMakerError.scriptError("Ingestion script failed")
        }

        return true
    }

    // MARK: - Proyectos

    /// Fetches active projects from FileMaker for a given company
    /// - Parameter companyId: The company ID to filter projects
    /// - Returns: Array of Proyecto objects
    func fetchProyectos(companyId: String) async throws -> [Proyecto] {
        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        guard let url = URL(string: "\(baseUrl)/layouts/@Projects/_find") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Query for projects by company
        // Using exact match syntax for idEmpresa, sorted by idProyecto descending
        let findRequest = ProyectoFindRequest(
            query: [
                "idEmpresa": "==\"\(companyId)\""
            ],
            sort: [
                ProyectoSortOrder(fieldName: "idProyecto", sortOrder: "descend")
            ],
            limit: 1000
        )

        request.httpBody = try JSONEncoder().encode(findRequest)

        logInfo("FileMaker fetchProyectos URL: \(url.absoluteString)")
        logInfo("FileMaker fetchProyectos body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        logInfo("FileMaker fetchProyectos response status: \(httpResponse.statusCode)")

        // Handle 401 - token expired
        if httpResponse.statusCode == 401 {
            clearToken()
            throw APIError.unauthorized
        }

        // Handle FileMaker error responses (400 with code 401 = no records)
        if httpResponse.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let messages = json["messages"] as? [[String: Any]],
               let firstMessage = messages.first,
               let code = firstMessage["code"] as? String {
                logInfo("FileMaker fetchProyectos error code: \(code)")
                // Code 401 = No records match the request - return empty array
                if code == "401" {
                    return []
                }
            }
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            logError("FileMaker fetchProyectos failed: \(responseBody)")
            return []
        }

        // Refresh token expiry on successful call
        refreshTokenExpiry()

        do {
            let recordsResponse = try JSONDecoder().decode(
                FileMakerRecordsResponse<ProyectoFieldData>.self,
                from: data
            )

            logInfo("FileMaker fetchProyectos found \(recordsResponse.response.data.count) projects")

            // Convert FileMaker records to Proyecto objects
            return recordsResponse.response.data.map { record in
                Proyecto(
                    id: "PRY-\(record.fieldData.idProyecto)",
                    idProyecto: record.fieldData.idProyecto,
                    descripcion: record.fieldData.descripcion,
                    estatus: ProyectoStatus(from: record.fieldData.estatus),
                    fechaRegistro: record.fieldData.fechaRegistro,
                    socioNegocio: record.fieldData.socioNegocio,
                    tipoProyecto: record.fieldData.tipoProyecto,
                    anio: record.fieldData.anio,
                    pk: record.fieldData.pk,
                    ubicacion: record.fieldData.ubicacion,
                    fechaInicio: record.fieldData.fechaInicio,
                    fechaFinal: record.fieldData.fechaFinal,
                    idEmpresa: record.fieldData.idEmpresa,
                    pkSocioNegocio: record.fieldData.pkSocioNegocio,
                    recId: record.fieldData.recId,
                    idSN: record.fieldData.idSN,
                    responsable: record.fieldData.responsable,
                    pkResponsable: record.fieldData.pkResponsable,
                    recordId: record.recordId,
                    presupuesto: record.fieldData.presupuesto
                )
            }
        } catch let decodingError as DecodingError {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            logError("FileMaker fetchProyectos decoding error: \(decodingError)")
            logError("Raw response: \(responseBody)")
            throw FileMakerError.invalidResponse("Error al procesar proyectos")
        }
    }

    /// Refreshes the token expiry time after a successful API call
    private func refreshTokenExpiry() {
        let newExpiry = Date().addingTimeInterval(600) // 10 minutes
        self.tokenExpiry = newExpiry
        try? KeychainManager.shared.storeTokenExpiry(newExpiry, for: .fileMakerTokenExpiry)
    }

    // MARK: - Pedidos

    /// Fetches pedidos from FileMaker for a given company
    /// - Parameter companyId: The company ID to filter pedidos
    /// - Returns: Array of Pedido objects
    func fetchPedidos(companyId: String) async throws -> [Pedido] {
        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        guard let url = URL(string: "\(baseUrl)/layouts/@Pedidos/_find") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Query for pedidos by company, sorted by idProyecto desc, then idPedido_ desc
        let findRequest = PedidoFindRequest(
            query: [
                "idEmpresa": "==\"\(companyId)\""
            ],
            sort: [
                ProyectoSortOrder(fieldName: "idProyecto", sortOrder: "descend"),
                ProyectoSortOrder(fieldName: "idPedido_", sortOrder: "descend")
            ],
            limit: 100
        )

        request.httpBody = try JSONEncoder().encode(findRequest)

        logInfo("FileMaker fetchPedidos URL: \(url.absoluteString)")
        logInfo("FileMaker fetchPedidos body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        logInfo("FileMaker fetchPedidos response status: \(httpResponse.statusCode)")

        // Handle 401 - token expired
        if httpResponse.statusCode == 401 {
            clearToken()
            throw APIError.unauthorized
        }

        // Handle FileMaker error responses (400 with code 401 = no records)
        if httpResponse.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let messages = json["messages"] as? [[String: Any]],
               let firstMessage = messages.first,
               let code = firstMessage["code"] as? String {
                logInfo("FileMaker fetchPedidos error code: \(code)")
                // Code 401 = No records match the request - return empty array
                if code == "401" {
                    return []
                }
            }
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            logError("FileMaker fetchPedidos failed: \(responseBody)")
            return []
        }

        // Refresh token expiry on successful call
        refreshTokenExpiry()

        do {
            let recordsResponse = try JSONDecoder().decode(
                FileMakerRecordsResponse<PedidoFieldData>.self,
                from: data
            )

            logInfo("FileMaker fetchPedidos found \(recordsResponse.response.data.count) pedidos")

            // Convert FileMaker records to Pedido objects
            return recordsResponse.response.data.map { record in
                let fieldData = record.fieldData
                return Pedido(
                    id: "\(fieldData.idProyecto)-\(fieldData.idPedido_)",
                    idPedido: fieldData.idPedido,
                    fecha: fieldData.fecha,
                    fechaCreacion: fieldData.fechaCreacion,
                    usuario: fieldData.idUsuario,
                    proveedor: fieldData.socioNegocioProveedor,
                    proyecto: fieldData.socioNegocioProyecto,
                    proyectoDescripcion: fieldData.proyectoDescripcion,
                    proyectoUbicacion: fieldData.proyectoUbicacion,
                    concepto: fieldData.concepto,
                    tipoPedido: fieldData.tipoPedido,
                    clase: fieldData.clase,
                    condicionesPago: fieldData.condicionesPago,
                    moneda: fieldData.moneda,
                    observaciones: fieldData.observaciones,
                    total: fieldData.totalN,
                    pagado: fieldData.pagado,
                    adeudo: fieldData.adeudo,
                    status: PedidoStatus(from: fieldData.estatus),
                    recordId: record.recordId,
                    cotizacionURL: fieldData.cotizacion,
                    facturaPDFURL: fieldData.facturaPDF,
                    facturaXMLURL: fieldData.facturaXML,
                    comprobacionURL: fieldData.comprobacion
                )
            }
        } catch let decodingError as DecodingError {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            logError("FileMaker fetchPedidos decoding error: \(decodingError)")
            logError("Raw response: \(responseBody)")
            throw FileMakerError.invalidResponse("Error al procesar pedidos")
        }
    }

    // MARK: - Update Login Time

    func updateLoginTime(recordId: String) async throws {
        let token = try await getToken()
        let baseUrl = try await getBaseUrl()

        guard let url = URL(string: "\(baseUrl)/layouts/_webappSalesContacts/records/\(recordId)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let formatter = ISO8601DateFormatter()
        let payload: [String: Any] = [
            "fieldData": [
                "LastLoginTime": formatter.string(from: Date())
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Don't throw - this is a non-critical update
            logWarning("Failed to update login time")
            return
        }
    }
}
