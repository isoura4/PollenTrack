import Foundation
import Combine

// NOTE: In production, the token should be stored in the iOS Keychain instead of UserDefaults
// for enhanced security. UserDefaults is used here for simplicity.

@MainActor
final class AuthStore: ObservableObject {
    // MARK: - Constants
    private enum Keys {
        static let token    = "auth.token"
        static let username = "auth.username"
        static let expiry   = "auth.expiry"
    }

    // MARK: - Published
    @Published private(set) var token: String?
    @Published private(set) var username: String = ""
    @Published private(set) var isLoggedIn: Bool = false

    // MARK: - Private
    private let tokenLifetimeSeconds: TimeInterval = 3600
    private var tokenExpiry: Date?

    // MARK: - Init
    init() {
        restoreSession()
    }

    // MARK: - Token validity
    var isTokenValid: Bool {
        guard let t = token, !t.isEmpty,
              let expiry = tokenExpiry else { return false }
        return Date() < expiry
    }

    // MARK: - Login
    func login(username: String, password: String) async throws {
        let url = URL(string: APIConstants.baseURL + "/api/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["username": username, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.networkError("Réponse invalide")
        }
        guard http.statusCode == 200 else {
            throw AuthError.invalidCredentials
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        let expiry = Date().addingTimeInterval(tokenLifetimeSeconds)

        self.token = authResponse.token
        self.username = username
        self.tokenExpiry = expiry
        self.isLoggedIn = true

        // Persist
        UserDefaults.standard.set(authResponse.token, forKey: Keys.token)
        UserDefaults.standard.set(username, forKey: Keys.username)
        UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: Keys.expiry)
    }

    // MARK: - Logout
    func logout() {
        token = nil
        username = ""
        tokenExpiry = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: Keys.token)
        UserDefaults.standard.removeObject(forKey: Keys.username)
        UserDefaults.standard.removeObject(forKey: Keys.expiry)
    }

    // MARK: - Restore session
    private func restoreSession() {
        guard
            let savedToken = UserDefaults.standard.string(forKey: Keys.token),
            !savedToken.isEmpty
        else { return }

        let expiryTimestamp = UserDefaults.standard.double(forKey: Keys.expiry)
        let expiry = Date(timeIntervalSince1970: expiryTimestamp)
        guard Date() < expiry else {
            // Token expired — clear stored values
            UserDefaults.standard.removeObject(forKey: Keys.token)
            UserDefaults.standard.removeObject(forKey: Keys.username)
            UserDefaults.standard.removeObject(forKey: Keys.expiry)
            return
        }

        self.token = savedToken
        self.username = UserDefaults.standard.string(forKey: Keys.username) ?? ""
        self.tokenExpiry = expiry
        self.isLoggedIn = true
    }
}

// MARK: - API Constants
enum APIConstants {
    static let baseURL        = "https://admindata.atmo-france.org"
    static let pollenEndpoint = "/api/opendata/pollen/"
    static let geocodeURL     = "https://api-adresse.data.gouv.fr/reverse/"
}
