import CoreLocation
import Foundation
import MapKit
import SwiftUI

@MainActor
final class ChargingSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var resolvedLocation: ResolvedSearchLocation?
    @Published private(set) var results: [ChargingSearchResult] = []
    @Published private(set) var selectedResult: ChargingSearchResult?
    @Published private(set) var isLoading = false
    @Published private(set) var statusMessage = "Search a postal code or place in Singapore."
    @Published private(set) var lastUpdatedTime: String?
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
            span: MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16)
        )
    )

    private let ltaClient: LTADataMallClient
    private let locationSearch: LocationSearchService

    init(
        ltaClient: LTADataMallClient = LTADataMallClient(),
        locationSearch: LocationSearchService = LocationSearchService()
    ) {
        self.ltaClient = ltaClient
        self.locationSearch = locationSearch
    }

    func search() async {
        await search(query)
    }

    func startAutoLocationDetection() {
        statusMessage = "Detecting your location..."
    }

    func showLocationMessage(_ message: String) {
        statusMessage = message
    }

    func searchCurrentLocation(_ coordinate: CLLocationCoordinate2D) async {
        let resolved = ResolvedSearchLocation(coordinate: coordinate, title: "Current location", postalCode: nil)
        await loadChargingPoints(for: resolved)
    }

    func select(_ result: ChargingSearchResult) {
        selectedResult = result
        cameraPosition = .region(
            MKCoordinateRegion(
                center: result.station.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
            )
        )
    }

    func openDirections(to result: ChargingSearchResult) {
        let placemark = MKPlacemark(coordinate: result.station.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = result.station.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func search(_ query: String) async {
        isLoading = true
        statusMessage = "Finding location..."
        defer { isLoading = false }

        do {
            let resolved = try await locationSearch.resolve(query)
            await loadChargingPoints(for: resolved)
        } catch {
            results = []
            selectedResult = nil
            resolvedLocation = nil
            statusMessage = error.localizedDescription
        }
    }

    private func loadChargingPoints(for resolved: ResolvedSearchLocation) async {
        isLoading = true
        statusMessage = "Loading LTA charging data..."
        resolvedLocation = resolved
        defer { isLoading = false }

        do {
            async let batchEnvelope = ltaClient.allChargingPoints()
            async let postalMatches = chargingPoints(forPostalCode: resolved.postalCode)

            let batch = try await batchEnvelope
            var locations = batch.evLocationsData

            if let nearbyPostalMatches = await postalMatches {
                locations = merge(locations, with: nearbyPostalMatches)
            }

            lastUpdatedTime = batch.lastUpdatedTime
            let origin = CLLocation(latitude: resolved.coordinate.latitude, longitude: resolved.coordinate.longitude)
            results = locations
                .map { station in
                    ChargingSearchResult(
                        station: station,
                        distance: origin.distance(from: CLLocation(latitude: station.latitude, longitude: station.longitude))
                    )
                }
                .sorted { $0.distance < $1.distance }

            selectedResult = results.first
            updateCamera(for: resolved.coordinate, stations: Array(results.prefix(5)))
            statusMessage = results.isEmpty ? "No EV charging points found." : "\(results.count) charging locations found."
        } catch {
            results = []
            selectedResult = nil
            statusMessage = error.localizedDescription
        }
    }

    private func chargingPoints(forPostalCode postalCode: String?) async -> [EVChargingLocation]? {
        guard let postalCode else {
            return nil
        }

        return try? await ltaClient.chargingPoints(nearPostalCode: postalCode)
    }

    private func merge(_ primary: [EVChargingLocation], with secondary: [EVChargingLocation]) -> [EVChargingLocation] {
        var byID = Dictionary(uniqueKeysWithValues: primary.map { ($0.id, $0) })

        for location in secondary {
            byID[location.id] = location
        }

        return Array(byID.values)
    }

    private func updateCamera(for origin: CLLocationCoordinate2D, stations: [ChargingSearchResult]) {
        let coordinates = [origin] + stations.map { $0.station.coordinate }
        let minLatitude = coordinates.map(\.latitude).min() ?? origin.latitude
        let maxLatitude = coordinates.map(\.latitude).max() ?? origin.latitude
        let minLongitude = coordinates.map(\.longitude).min() ?? origin.longitude
        let maxLongitude = coordinates.map(\.longitude).max() ?? origin.longitude

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.015, (maxLatitude - minLatitude) * 1.6),
            longitudeDelta: max(0.015, (maxLongitude - minLongitude) * 1.6)
        )

        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}
