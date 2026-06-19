import Foundation

enum LTADataMallError: LocalizedError {
    case missingBatchLink
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingBatchLink:
            return "LTA did not return a batch download link."
        case .invalidResponse:
            return "LTA returned an unexpected response."
        }
    }
}

final class LTADataMallClient {
    private let accountKey: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        accountKey: String = Bundle.main.object(forInfoDictionaryKey: "LTADataMallAccountKey") as? String ?? "",
        session: URLSession = .shared
    ) {
        self.accountKey = accountKey
        self.session = session
        decoder = JSONDecoder()
    }

    func chargingPoints(nearPostalCode postalCode: String) async throws -> [EVChargingLocation] {
        var components = URLComponents(string: "https://datamall2.mytransport.sg/ltaodataservice/EVChargingPoints")!
        components.queryItems = [
            URLQueryItem(name: "PostalCode", value: postalCode)
        ]

        let envelope: EVPostalEnvelope = try await get(components.url!)
        return envelope.value.evLocationsData
    }

    func allChargingPoints() async throws -> EVBatchEnvelope {
        let linkEnvelope: EVBatchLinkEnvelope = try await get(URL(string: "https://datamall2.mytransport.sg/ltaodataservice/EVCBatch")!)

        guard let batchURL = linkEnvelope.value.first?.link else {
            throw LTADataMallError.missingBatchLink
        }

        return try await get(batchURL, includeAccountKey: false)
    }

    private func get<T: Decodable>(_ url: URL, includeAccountKey: Bool = true) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        if includeAccountKey {
            guard !accountKey.isEmpty else {
                throw LTADataMallError.invalidResponse
            }

            request.setValue(accountKey, forHTTPHeaderField: "AccountKey")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw LTADataMallError.invalidResponse
        }

        return try decoder.decode(T.self, from: data)
    }
}
