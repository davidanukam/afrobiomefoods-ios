import MapKit
import SwiftUI
import UIKit

struct ServicesView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors
    @State private var mode = "list"
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.9849, longitude: -81.2453),
        span: MKCoordinateSpan(latitudeDelta: 0.14, longitudeDelta: 0.18)
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                StyledText(text: model.t("sourcingGuide"), kind: .subtitle, color: colors.text)
                StyledText(text: model.t("sourcingGuideIntro"), kind: .body, color: colors.textMuted)
                HStack(spacing: 10) {
                    Chip(label: model.t("listView"), active: mode == "list", expands: true) { mode = "list" }
                    Chip(label: model.t("mapView"), active: mode == "map", expands: true) { mode = "map" }
                }
                .padding(.vertical, 4)

                if mode == "map" {
                    Map(coordinateRegion: $region, annotationItems: model.services.filter(\.hasCoordinates)) { item in
                        MapMarker(coordinate: CLLocationCoordinate2D(latitude: item.lat, longitude: item.lng))
                    }
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .accessibilityLabel(model.t("mapView"))
                    .onAppear { region = fittedRegion(model.services) }
                    .onChange(of: model.services.map(\.service_id).joined(separator: "|")) { _ in
                        region = fittedRegion(model.services)
                    }
                }

                ForEach(model.services) { item in
                    serviceCard(item)
                }
            }
            .padding(20)
        }
        .appBackground()
        .refreshable { await model.refreshServices() }
        .task { await model.refreshServices() }
    }

    private func serviceCard(_ item: ServiceItem) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                StyledText(text: item.name, kind: .subtitle, color: colors.text)
                if !item.address.isEmpty {
                    Button {
                        openMaps(item)
                    } label: {
                        StyledText(text: item.address, kind: .body, color: colors.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(model.t("openInMaps")): \(item.address)")
                }
                ForEach(item.emails, id: \.self) { email in
                    Button {
                        open(URL(string: "mailto:\(email)"))
                    } label: {
                        StyledText(text: email, kind: .caption, color: colors.accent)
                    }
                    .buttonStyle(.plain)
                }
                if let website = item.website, !website.isEmpty, let url = webURL(website) {
                    Button {
                        open(url)
                    } label: {
                        StyledText(text: website.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: ""), kind: .caption, color: colors.accent)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    let digits = item.contact.filter { "+0123456789".contains($0) }
                    open(URL(string: "tel:\(digits)"))
                } label: {
                    Text("\(model.t("call")): \(item.contact)")
                        .font(.system(size: 15 * model.settings.fontScale.multiplier, weight: .semibold))
                        .foregroundStyle(colors.inverse)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(colors.forest)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                Button {
                    openMaps(item)
                } label: {
                    Text(model.t("openInMaps"))
                        .font(.system(size: 15 * model.settings.fontScale.multiplier, weight: .semibold))
                        .foregroundStyle(colors.accent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .overlay(Capsule().stroke(colors.forest, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func fittedRegion(_ items: [ServiceItem]) -> MKCoordinateRegion {
        let valid = items.filter(\.hasCoordinates)
        guard !valid.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 42.9849, longitude: -81.2453),
                span: MKCoordinateSpan(latitudeDelta: 0.14, longitudeDelta: 0.18)
            )
        }
        let lats = valid.map(\.lat)
        let lngs = valid.map(\.lng)
        let minLat = lats.min() ?? 42.9849
        let maxLat = lats.max() ?? 42.9849
        let minLng = lngs.min() ?? -81.2453
        let maxLng = lngs.max() ?? -81.2453
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.5, 0.06),
                longitudeDelta: max((maxLng - minLng) * 1.5, 0.06)
            )
        )
    }

    private func openMaps(_ item: ServiceItem) {
        if item.hasCoordinates {
            var parts = URLComponents(string: "https://maps.apple.com/")
            parts?.queryItems = [
                URLQueryItem(name: "ll", value: "\(item.lat),\(item.lng)"),
                URLQueryItem(name: "q", value: item.name),
            ]
            open(parts?.url)
            return
        }
        var parts = URLComponents(string: "https://maps.apple.com/")
        parts?.queryItems = [URLQueryItem(name: "q", value: item.address.isEmpty ? item.name : item.address)]
        open(parts?.url)
    }

    private func webURL(_ raw: String) -> URL? {
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") { return URL(string: raw) }
        return URL(string: "https://\(raw)")
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }
}
