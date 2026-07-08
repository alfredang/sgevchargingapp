import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.car.fill")
                                .font(.title)
                                .foregroundStyle(Theme.primary)
                                .frame(width: 44, height: 44)
                                .background(Theme.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("SG EV Charging")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Theme.ink)
                                Text("Version \(appVersion)")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.mutedInk)
                            }
                        }

                        Text("Find nearby electric vehicle charging points across Singapore. Charging locations and availability are sourced from the LTA DataMall public data feed and shown on Apple Maps.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.mutedInk)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Developer")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.mutedInk)

                        Text("Tertiary Infotech Academy Pte. Ltd.")
                            .font(.headline)
                            .foregroundStyle(Theme.ink)

                        Link(destination: URL(string: "https://www.tertiaryinfotech.com")!) {
                            Label("tertiaryinfotech.com", systemImage: "safari")
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Data source")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.mutedInk)

                        Text("EV charging data is provided by LTA DataMall.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)

                        Link(destination: URL(string: "https://datamall.lta.gov.sg")!) {
                            Label("datamall.lta.gov.sg", systemImage: "link")
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()

                    HStack {
                        Text("Version")
                            .font(.subheadline)
                            .foregroundStyle(Theme.mutedInk)
                        Spacer()
                        Text(appVersion)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                    }
                    .appCard()
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AboutView()
}
