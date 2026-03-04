import Foundation
import CoreLocation

@MainActor
final class LocationService: NSObject, ObservableObject {
    // MARK: - Published
    @Published private(set) var inseeCode: String = ""
    @Published private(set) var cityName: String = ""
    @Published private(set) var isLocating: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private
    private let locationManager = CLLocationManager()

    // MARK: - Init
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Request location
    func requestLocation() {
        errorMessage = nil
        isLocating = true

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            isLocating = false
            errorMessage = "Localisation refusée. Activez-la dans Réglages > PollenTrack."
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        @unknown default:
            isLocating = false
            errorMessage = "Statut de localisation inconnu."
        }
    }

    // MARK: - Reverse geocode
    private func reverseGeocode(latitude: Double, longitude: Double) async {
        var components = URLComponents(string: APIConstants.geocodeURL)!
        components.queryItems = [
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "lat", value: String(latitude))
        ]
        guard let url = components.url else {
            isLocating = false
            errorMessage = "URL de géocodage invalide."
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let geoJSON = try JSONDecoder().decode(GeoJSONResponse.self, from: data)
            guard let feature = geoJSON.features.first else {
                isLocating = false
                errorMessage = "Commune introuvable pour cette position."
                return
            }
            inseeCode = feature.properties.citycode
            cityName  = feature.properties.city
        } catch {
            errorMessage = "Géocodage impossible : \(error.localizedDescription)"
        }
        isLocating = false
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                isLocating = false
                errorMessage = "Localisation refusée. Activez-la dans Réglages > PollenTrack."
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            await reverseGeocode(latitude: location.coordinate.latitude,
                                 longitude: location.coordinate.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            isLocating = false
            errorMessage = "Erreur de localisation : \(error.localizedDescription)"
        }
    }
}

// MARK: - GeoJSON models
private struct GeoJSONResponse: Decodable {
    let features: [GeoJSONFeature]
}

private struct GeoJSONFeature: Decodable {
    let properties: GeoJSONProperties
}

private struct GeoJSONProperties: Decodable {
    let citycode: String
    let city: String
}
