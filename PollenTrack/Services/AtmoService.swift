import Foundation

@MainActor
final class AtmoService: ObservableObject {
    // MARK: - Published
    @Published private(set) var pollenData: [PollenData] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var communeName: String = ""

    // MARK: - Fetch pollen
    // Throws AuthError.tokenExpired on a 401 response so callers can react (e.g., force logout).
    // Other errors are surfaced via `errorMessage` to avoid crashing the UI.
    func fetchPollen(token: String, codeZone: String) async throws {
        isLoading = true
        errorMessage = nil

        let today = Date()
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        let startDate = formatter.string(from: today)
        let endDate   = formatter.string(from: calendar.date(byAdding: .day, value: 2, to: today) ?? today)

        var components = URLComponents(string: APIConstants.baseURL + APIConstants.pollenEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "code_zone",      value: codeZone),
            URLQueryItem(name: "date_ech__gte",  value: startDate),
            URLQueryItem(name: "date_ech__lte",  value: endDate)
        ]

        guard let url = components.url else {
            isLoading = false
            errorMessage = "URL invalide pour la requête pollen."
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw PollenError.networkError("Réponse invalide")
            }
            if http.statusCode == 401 {
                isLoading = false
                throw AuthError.tokenExpired
            }
            guard http.statusCode == 200 else {
                throw PollenError.networkError("Code HTTP \(http.statusCode)")
            }

            let apiResponse = try JSONDecoder().decode(PollenAPIResponse.self, from: data)
            let sorted = apiResponse.results.sorted { lhs, rhs in
                (lhs.date ?? .distantPast) < (rhs.date ?? .distantPast)
            }
            pollenData = sorted
            communeName = sorted.first?.lib_zone ?? ""
        } catch let authError as AuthError {
            throw authError  // propagate to caller to handle (e.g. logout)
        } catch let error as PollenError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Erreur inattendue : \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Clear
    func clear() {
        pollenData = []
        communeName = ""
        errorMessage = nil
    }
}
