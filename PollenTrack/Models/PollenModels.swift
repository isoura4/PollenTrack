import SwiftUI
import Foundation

// MARK: - Auth

struct AuthResponse: Decodable {
    let token: String
}

// MARK: - Pollen Level

enum PollenLevel: Int, CaseIterable {
    case unavailable = 0
    case veryLow = 1
    case low = 2
    case moderate = 3
    case high = 4
    case veryHigh = 5
    case extremelyHigh = 6

    var label: String {
        switch self {
        case .unavailable:     return "Indisponible"
        case .veryLow:         return "Très faible"
        case .low:             return "Faible"
        case .moderate:        return "Modéré"
        case .high:            return "Élevé"
        case .veryHigh:        return "Très élevé"
        case .extremelyHigh:   return "Extrêmement élevé"
        }
    }

    var color: Color {
        switch self {
        case .unavailable:     return Color(hex: "#DDDDDD")
        case .veryLow:         return Color(hex: "#50F0E6")
        case .low:             return Color(hex: "#50CCAA")
        case .moderate:        return Color(hex: "#F0E641")
        case .high:            return Color(hex: "#FF5050")
        case .veryHigh:        return Color(hex: "#960032")
        case .extremelyHigh:   return Color(hex: "#872181")
        }
    }

    var textColor: Color {
        rawValue >= 4 ? .white : .black
    }
}

// MARK: - Taxon

struct TaxonData: Identifiable {
    let id: String
    let name: String
    let icon: String
    let code: Int
    let concentration: Double?
    let level: PollenLevel

    init(id: String, name: String, icon: String, code: Int, concentration: Double?) {
        self.id = id
        self.name = name
        self.icon = icon
        self.code = code
        self.concentration = concentration
        self.level = PollenLevel(rawValue: code) ?? .unavailable
    }
}

// MARK: - Pollen Data

struct PollenData: Decodable, Identifiable {
    let id: UUID = UUID()
    let date_ech: String?
    let code_qual: Int?
    let lib_qual: String?
    let coul_qual: String?
    let code_zone: String?
    let lib_zone: String?
    let code_aul: Int?
    let code_boul: Int?
    let code_oliv: Int?
    let code_gram: Int?
    let code_arm: Int?
    let code_ambr: Int?
    let conc_aul: Double?
    let conc_boul: Double?
    let conc_oliv: Double?
    let conc_gram: Double?
    let conc_arm: Double?
    let conc_ambr: Double?
    let pollen_resp: String?
    let alerte: Bool?

    enum CodingKeys: String, CodingKey {
        case date_ech, code_qual, lib_qual, coul_qual, code_zone, lib_zone
        case code_aul, code_boul, code_oliv, code_gram, code_arm, code_ambr
        case conc_aul, conc_boul, conc_oliv, conc_gram, conc_arm, conc_ambr
        case pollen_resp, alerte
    }

    var date: Date? {
        guard let raw = date_ech else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: raw)
    }

    var formattedDate: String {
        guard let d = date else { return date_ech ?? "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: d)
    }

    var pollenLevel: PollenLevel {
        PollenLevel(rawValue: code_qual ?? 0) ?? .unavailable
    }

    var taxons: [TaxonData] {
        [
            TaxonData(id: "aul",  name: "Aulne",       icon: "🌳", code: code_aul  ?? 0, concentration: conc_aul),
            TaxonData(id: "boul", name: "Bouleau",      icon: "🍃", code: code_boul ?? 0, concentration: conc_boul),
            TaxonData(id: "oliv", name: "Olivier",      icon: "🫒", code: code_oliv ?? 0, concentration: conc_oliv),
            TaxonData(id: "gram", name: "Graminées",    icon: "🌾", code: code_gram ?? 0, concentration: conc_gram),
            TaxonData(id: "arm",  name: "Armoise",      icon: "🌱", code: code_arm  ?? 0, concentration: conc_arm),
            TaxonData(id: "ambr", name: "Ambroisie",    icon: "⚠️", code: code_ambr ?? 0, concentration: conc_ambr),
        ]
    }
}

// MARK: - API Response

struct PollenAPIResponse: Decodable {
    let count: Int?
    let results: [PollenData]
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case tokenExpired
    case invalidCredentials
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .tokenExpired:
            return "La session a expiré. Veuillez vous reconnecter."
        case .invalidCredentials:
            return "Identifiants incorrects."
        case .networkError(let msg):
            return "Erreur réseau : \(msg)"
        }
    }
}

enum PollenError: LocalizedError {
    case noData
    case decodingError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .noData:
            return "Aucune donnée disponible pour cette commune."
        case .decodingError(let msg):
            return "Erreur de décodage : \(msg)"
        case .networkError(let msg):
            return "Erreur réseau : \(msg)"
        }
    }
}
