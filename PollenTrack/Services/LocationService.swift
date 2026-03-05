import Foundation
import CoreLocation

@MainActor
final class LocationService: NSObject, ObservableObject {
    // MARK: - Published
    @Published private(set) var inseeCode: String = ""
    @Published private(set) var cityName: String = ""
    @Published private(set) var isLocating: Bool = false
    @Published var errorMessage: String?
    /// When true the user chose to enter a postal code instead of using GPS.
    @Published var usingPostalCode: Bool = false

    // MARK: - Private
    private let locationManager = CLLocationManager()

    // MARK: - Init
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Request location (GPS)
    func requestLocation() {
        usingPostalCode = false
        errorMessage = nil
        isLocating = true

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            isLocating = false
            errorMessage = "Localisation refusée. Activez-la dans Réglages > PollenTrack, ou saisissez votre code postal."
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        @unknown default:
            isLocating = false
            errorMessage = "Statut de localisation inconnu."
        }
    }

    // MARK: - Lookup by postal code
    /// Resolves a French 5-digit postal code to an INSEE code and city name
    /// using the French government geo API (geo.api.gouv.fr).
    /// No GPS coordinates are sent — only the postal code.
    func lookupPostalCode(_ postalCode: String) async {
        let trimmed = postalCode.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 5, trimmed.allSatisfy(\.isNumber) else {
            errorMessage = "Code postal invalide. Saisissez 5 chiffres (ex : 75001)."
            return
        }

        errorMessage = nil
        isLocating = true
        usingPostalCode = true

        guard var components = URLComponents(string: APIConstants.communesURL) else {
            isLocating = false
            errorMessage = "URL de recherche invalide."
            return
        }
        components.queryItems = [
            URLQueryItem(name: "codePostal", value: trimmed),
            URLQueryItem(name: "fields",     value: "nom,code"),
            URLQueryItem(name: "limit",      value: "10")
        ]

        guard let url = components.url else {
            isLocating = false
            errorMessage = "URL de recherche invalide."
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let communes = try JSONDecoder().decode([CommuneResponse].self, from: data)
            guard let commune = communes.first else {
                isLocating = false
                errorMessage = "Aucune commune trouvée pour le code postal \(trimmed)."
                return
            }
            inseeCode = commune.code
            cityName  = commune.nom
        } catch {
            errorMessage = "Recherche impossible : \(error.localizedDescription)"
        }
        isLocating = false
    }

    // MARK: - Reverse geocode (GPS → INSEE)
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

// MARK: - GeoJSON models (reverse geocoding)
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

// MARK: - Commune response (postal code lookup)
private struct CommuneResponse: Decodable {
    let nom: String
    let code: String   // INSEE code
}
