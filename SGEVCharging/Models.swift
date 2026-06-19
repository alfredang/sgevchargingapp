import CoreLocation
import Foundation
import MapKit

struct ChargingSearchResult: Identifiable, Hashable {
    let station: EVChargingLocation
    let distance: CLLocationDistance

    var id: String { station.id }
}

struct EVChargingLocation: Identifiable, Decodable, Hashable {
    let address: String
    let name: String
    let longitude: Double
    let latitude: Double
    let postalCode: String?
    let locationId: String?
    let status: String?
    let chargingPoints: [ChargingPoint]

    var id: String {
        locationId ?? "\(name)-\(latitude)-\(longitude)"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var availableConnectors: Int {
        chargingPoints.flatMap(\.plugTypes).flatMap(\.evIds).filter { $0.status == "1" }.count
    }

    var occupiedConnectors: Int {
        chargingPoints.flatMap(\.plugTypes).flatMap(\.evIds).filter { $0.status == "0" }.count
    }

    var totalConnectors: Int {
        chargingPoints.flatMap(\.plugTypes).flatMap(\.evIds).count
    }

    var availabilityText: String {
        if availableConnectors > 0 {
            return "\(availableConnectors) available"
        }

        if occupiedConnectors > 0 {
            return "Occupied"
        }

        return "Unavailable"
    }

    var availabilityColorName: String {
        availableConnectors > 0 ? "green" : occupiedConnectors > 0 ? "orange" : "gray"
    }

    var operators: String {
        let names = Set(chargingPoints.map(\.operatorName).filter { !$0.isEmpty })
        return names.sorted().joined(separator: ", ")
    }

    var plugSummary: String {
        let plugs = chargingPoints
            .flatMap(\.plugTypes)
            .map { plug in
                if let speed = plug.speedInKW {
                    return "\(plug.plugType) \(speed.cleanKW)kW"
                }
                return plug.plugType
            }

        return Array(Set(plugs)).sorted().joined(separator: ", ")
    }

    enum CodingKeys: String, CodingKey {
        case address
        case name
        case longitude
        case longtitude
        case latitude
        case postalCode
        case locationId
        case status
        case chargingPoints
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "EV charging point"
        longitude = try container.decodeFlexibleDouble(forKeys: [.longitude, .longtitude])
        latitude = try container.decodeFlexibleDouble(forKeys: [.latitude])
        postalCode = try container.decodeFlexibleStringIfPresent(forKey: .postalCode)
        locationId = try container.decodeFlexibleStringIfPresent(forKey: .locationId)
        status = try container.decodeFlexibleStringIfPresent(forKey: .status)
        chargingPoints = try container.decodeIfPresent([ChargingPoint].self, forKey: .chargingPoints) ?? []
    }

    static func == (lhs: EVChargingLocation, rhs: EVChargingLocation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ChargingPoint: Decodable, Hashable {
    let status: String
    let operatingHours: String
    let operatorName: String
    let position: String
    let name: String
    let plugTypes: [PlugType]

    enum CodingKeys: String, CodingKey {
        case status
        case operatingHours
        case operatorName = "operator"
        case position
        case name
        case plugTypes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeFlexibleStringIfPresent(forKey: .status) ?? ""
        operatingHours = try container.decodeFlexibleStringIfPresent(forKey: .operatingHours) ?? ""
        operatorName = try container.decodeFlexibleStringIfPresent(forKey: .operatorName) ?? ""
        position = try container.decodeFlexibleStringIfPresent(forKey: .position) ?? ""
        name = try container.decodeFlexibleStringIfPresent(forKey: .name) ?? ""
        plugTypes = try container.decodeIfPresent([PlugType].self, forKey: .plugTypes) ?? []
    }
}

struct PlugType: Decodable, Hashable {
    let plugType: String
    let current: String?
    let speedInKW: Double?
    let price: String?
    let priceType: String?
    let evIds: [EVConnector]

    enum CodingKeys: String, CodingKey {
        case plugType
        case current
        case powerRating
        case chargingSpeed
        case price
        case priceType
        case evIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        plugType = try container.decodeFlexibleStringIfPresent(forKey: .plugType) ?? "Plug"
        current = try container.decodeFlexibleStringIfPresent(forKey: .current)
            ?? container.decodeNonNumericStringIfPresent(forKey: .powerRating)
        speedInKW = try container.decodeFlexibleDoubleIfPresent(forKeys: [.chargingSpeed, .powerRating])
        price = try container.decodeFlexibleStringIfPresent(forKey: .price)
        priceType = try container.decodeFlexibleStringIfPresent(forKey: .priceType)
        evIds = try container.decodeIfPresent([EVConnector].self, forKey: .evIds) ?? []
    }
}

struct EVConnector: Decodable, Hashable {
    let id: String?
    let evCpId: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case evCpId
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleStringIfPresent(forKey: .id)
        evCpId = try container.decodeFlexibleStringIfPresent(forKey: .evCpId) ?? UUID().uuidString
        status = try container.decodeFlexibleStringIfPresent(forKey: .status) ?? ""
    }
}

struct EVBatchEnvelope: Decodable {
    let lastUpdatedTime: String?
    let evLocationsData: [EVChargingLocation]

    enum CodingKeys: String, CodingKey {
        case lastUpdatedTime = "LastUpdatedTime"
        case evLocationsData
    }
}

struct EVPostalEnvelope: Decodable {
    let value: EVPostalValue
}

struct EVPostalValue: Decodable {
    let evLocationsData: [EVChargingLocation]
}

struct EVBatchLinkEnvelope: Decodable {
    let value: [EVBatchLink]
}

struct EVBatchLink: Decodable {
    let link: URL

    enum CodingKeys: String, CodingKey {
        case link = "Link"
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKeys keys: [Key]) throws -> Double {
        for key in keys {
            if let value = try decodeFlexibleDoubleIfPresent(forKey: key) {
                return value
            }
        }

        throw DecodingError.keyNotFound(
            keys[0],
            DecodingError.Context(codingPath: codingPath, debugDescription: "Missing numeric value")
        )
    }

    func decodeFlexibleDoubleIfPresent(forKeys keys: [Key]) throws -> Double? {
        for key in keys {
            if let value = try decodeFlexibleDoubleIfPresent(forKey: key) {
                return value
            }
        }

        return nil
    }

    func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
        if let double = try? decodeIfPresent(Double.self, forKey: key) {
            return double
        }

        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Double(string)
        }

        return nil
    }

    func decodeNonNumericStringIfPresent(forKey key: Key) throws -> String? {
        guard let string = try? decodeIfPresent(String.self, forKey: key), Double(string) == nil else {
            return nil
        }

        return string
    }

    func decodeFlexibleStringIfPresent(forKey key: Key) throws -> String? {
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return string
        }

        if let int = try? decodeIfPresent(Int.self, forKey: key) {
            return String(int)
        }

        if let double = try? decodeIfPresent(Double.self, forKey: key) {
            return String(double)
        }

        return nil
    }
}

private extension Double {
    var cleanKW: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
