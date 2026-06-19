import MapKit
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChargingSearchViewModel()
    @StateObject private var locationProvider = UserLocationProvider()
    @State private var didRequestAutomaticLocation = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                map
                    .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 12) {
                    searchPanel
                    resultSummary
                    Spacer()
                    nearestPanel
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .background(Theme.background)
            .navigationTitle("SG EV Charging")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.startAutoLocationDetection()
                        locationProvider.requestLocation()
                    } label: {
                        Image(systemName: "location.fill")
                    }
                    .accessibilityLabel("Use current location")
                }
            }
            .onAppear {
                requestAutomaticLocationIfNeeded()
            }
            .onChange(of: locationProvider.coordinate) { _, coordinate in
                guard let coordinate else {
                    return
                }

                Task {
                    await viewModel.searchCurrentLocation(coordinate)
                }
            }
            .onChange(of: locationProvider.authorizationStatus) { _, status in
                if status == .denied || status == .restricted {
                    viewModel.showLocationMessage("Location access is off. Search by postal code or enable location in Settings.")
                }
            }
            .onChange(of: locationProvider.locationErrorMessage) { _, message in
                if let message {
                    viewModel.showLocationMessage(message)
                }
            }
        }
    }

    private var map: some View {
        Map(position: $viewModel.cameraPosition) {
            UserAnnotation()

            if let resolved = viewModel.resolvedLocation {
                Annotation(resolved.title, coordinate: resolved.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Theme.secondary)
                        .shadow(radius: 3)
                }
            }

            ForEach(viewModel.results.prefix(25)) { result in
                Marker(
                    result.station.name,
                    systemImage: result.station.availableConnectors > 0 ? "bolt.car.fill" : "bolt.trianglebadge.exclamationmark.fill",
                    coordinate: result.station.coordinate
                )
                .tint(result.station.availableConnectors > 0 ? .green : .orange)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
            MapUserLocationButton()
        }
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.mutedInk)

                TextField("Postal code or place", text: $viewModel.query)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
                    .focused($searchFocused)
                    .onSubmit {
                        runSearch()
                    }

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.mutedInk)
                    }
                    .accessibilityLabel("Clear search")
                }

                Button {
                    runSearch()
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.primary)
                    }
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Search")
            }

            HStack(spacing: 8) {
                Label(viewModel.statusMessage, systemImage: viewModel.isLoading ? "arrow.triangle.2.circlepath" : "info.circle")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedInk)
                    .lineLimit(2)

                Spacer()
            }
        }
        .appCard()
    }

    private var resultSummary: some View {
        HStack(spacing: 10) {
            if let lastUpdated = viewModel.lastUpdatedTime {
                Label(lastUpdated, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedInk)
            }

            Spacer()

            if let first = viewModel.results.first {
                Label(distanceText(first.distance), systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.caption)
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .opacity(viewModel.results.isEmpty ? 0 : 1)
    }

    private var nearestPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selected = viewModel.selectedResult {
                ChargingResultCard(
                    result: selected,
                    isNearest: true,
                    onDirections: {
                        viewModel.openDirections(to: selected)
                    }
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.results.prefix(8)) { result in
                            Button {
                                viewModel.select(result)
                            } label: {
                                MiniResultChip(result: result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func runSearch() {
        searchFocused = false
        Task {
            await viewModel.search()
        }
    }

    private func requestAutomaticLocationIfNeeded() {
        guard !didRequestAutomaticLocation else {
            return
        }

        didRequestAutomaticLocation = true
        viewModel.startAutoLocationDetection()
        locationProvider.requestLocation()
    }

    private func distanceText(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        }

        return "\(Int(distance)) m"
    }
}

private struct ChargingResultCard: View {
    let result: ChargingSearchResult
    let isNearest: Bool
    let onDirections: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: result.station.availableConnectors > 0 ? "bolt.car.fill" : "bolt.trianglebadge.exclamationmark.fill")
                    .font(.title2)
                    .foregroundStyle(result.station.availableConnectors > 0 ? .green : .orange)
                    .frame(width: 34, height: 34)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(isNearest ? "Nearest charging point" : "Charging point")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedInk)

                    Text(result.station.name)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)

                    Text(result.station.address)
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedInk)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                InfoPill(icon: "bolt.fill", text: result.station.availabilityText)
                InfoPill(icon: "location", text: distanceText(result.distance))
                if result.station.totalConnectors > 0 {
                    InfoPill(icon: "powerplug.fill", text: "\(result.station.totalConnectors) plugs")
                }
            }

            if !result.station.operators.isEmpty || !result.station.plugSummary.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if !result.station.operators.isEmpty {
                        Text(result.station.operators)
                            .font(.footnote)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)
                    }

                    if !result.station.plugSummary.isEmpty {
                        Text(result.station.plugSummary)
                            .font(.footnote)
                            .foregroundStyle(Theme.mutedInk)
                            .lineLimit(2)
                    }
                }
            }

            Button(action: onDirections) {
                Label("Directions in Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
        .appCard()
    }

    private func distanceText(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        }

        return "\(Int(distance)) m"
    }
}

private struct MiniResultChip: View {
    let result: ChargingSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(result.station.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .frame(width: 132, alignment: .leading)

            HStack {
                Circle()
                    .fill(result.station.availableConnectors > 0 ? .green : .orange)
                    .frame(width: 7, height: 7)

                Text(result.station.availabilityText)
                    .font(.caption2)
                    .foregroundStyle(Theme.mutedInk)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(width: 154, height: 76, alignment: .topLeading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Theme.background, in: Capsule())
            .foregroundStyle(Theme.ink)
    }
}

#Preview {
    ContentView()
}
