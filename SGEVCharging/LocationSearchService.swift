import CoreLocation
import Foundation

struct ResolvedSearchLocation {
    let coordinate: CLLocationCoordinate2D
    let title: String
    let postalCode: String?
}

enum LocationSearchError: LocalizedError {
    case emptyQuery
    case notFound

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Enter a Singapore postal code or place."
        case .notFound:
            return "I could not find that place in Singapore."
        }
    }
}

final class LocationSearchService {
    private let geocoder = CLGeocoder()

    func resolve(_ query: String) async throws -> ResolvedSearchLocation {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw LocationSearchError.emptyQuery
        }

        let lookup = trimmed.isSingaporePostalCode ? "Singapore \(trimmed)" : "\(trimmed), Singapore"
        let placemarks = try await geocoder.geocodeAddressString(lookup, in: singaporeRegion)

        guard let placemark = placemarks.first, let location = placemark.location else {
            throw LocationSearchError.notFound
        }

        let title = [placemark.name, placemark.locality]
            .compactMap { $0 }
            .removingDuplicates()
            .joined(separator: ", ")

        return ResolvedSearchLocation(
            coordinate: location.coordinate,
            title: title.isEmpty ? trimmed : title,
            postalCode: placemark.postalCode ?? (trimmed.isSingaporePostalCode ? trimmed : nil)
        )
    }

    private var singaporeRegion: CLRegion {
        CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
            radius: 35_000,
            identifier: "Singapore"
        )
    }
}

private extension String {
    var isSingaporePostalCode: Bool {
        range(of: #"^\d{6}$"#, options: .regularExpression) != nil
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
