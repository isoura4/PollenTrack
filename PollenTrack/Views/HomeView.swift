import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authStore:     AuthStore
    @EnvironmentObject private var atmoService:   AtmoService
    @EnvironmentObject private var locationService: LocationService

    private var todayData: PollenData? {
        atmoService.pollenData.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Location bar
                    locationBar

                    if atmoService.isLoading || locationService.isLocating {
                        ProgressView("Chargement…")
                            .padding(.top, 40)
                    } else if let error = atmoService.errorMessage ?? locationService.errorMessage {
                        errorView(message: error)
                    } else if let data = todayData {
                        // Alert banner
                        if data.alerte == true {
                            alertBanner(pollen: data.pollen_resp)
                        }

                        // Main pollen card
                        mainPollenCard(data: data)

                        // Taxon details
                        taxonSection(data: data)

                        // Recommendations
                        recommendationsSection(level: data.pollenLevel)
                    } else {
                        Text("Aucune donnée disponible")
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    }
                }
                .padding()
            }
            .refreshable {
                await refresh()
            }
            .navigationTitle("Indice Pollen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        locationService.requestLocation()
                    } label: {
                        Image(systemName: "location.circle")
                            .accessibilityLabel("Actualiser la localisation")
                    }
                }
            }
        }
    }

    // MARK: - Location bar
    private var locationBar: some View {
        HStack(spacing: 8) {
            if locationService.isLocating {
                Image(systemName: "location.fill")
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse)
                    .accessibilityLabel("Localisation en cours")
            } else {
                Image(systemName: "location.fill")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            let city = locationService.cityName.isEmpty
                ? (atmoService.communeName.isEmpty ? "Localisation…" : atmoService.communeName)
                : locationService.cityName
            Text(city)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Alert banner
    private func alertBanner(pollen: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Alerte pollen")
                    .font(.headline)
                if let p = pollen, !p.isEmpty {
                    Text("Taxon responsable : \(p)")
                        .font(.caption)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alerte pollen" + (pollen.map { ". Taxon responsable : \($0)" } ?? ""))
    }

    // MARK: - Main pollen card
    private func mainPollenCard(data: PollenData) -> some View {
        let level = data.pollenLevel
        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(level.rawValue)/6")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(level.textColor)

                    Text(level.label)
                        .font(.title2.bold())
                        .foregroundStyle(level.textColor)

                    if let pollen = data.pollen_resp, !pollen.isEmpty {
                        Text("Taxon dominant : \(pollen)")
                            .font(.caption)
                            .foregroundStyle(level.textColor.opacity(0.85))
                    }
                }
                Spacer()
                Image(systemName: "wind")
                    .font(.system(size: 44))
                    .foregroundStyle(level.textColor.opacity(0.6))
                    .accessibilityHidden(true)
            }

            HStack {
                Text(data.formattedDate)
                    .font(.caption)
                    .foregroundStyle(level.textColor.opacity(0.75))
                Spacer()
                if let zone = data.lib_zone {
                    Text(zone)
                        .font(.caption)
                        .foregroundStyle(level.textColor.opacity(0.75))
                }
            }
        }
        .padding(20)
        .background(level.color)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: level.color.opacity(0.45), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Indice pollen : \(level.rawValue) sur 6, \(level.label)")
    }

    // MARK: - Taxon section
    private func taxonSection(data: PollenData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Détail par taxon")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(data.taxons) { taxon in
                taxonRow(taxon: taxon)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func taxonRow(taxon: TaxonData) -> some View {
        HStack(spacing: 12) {
            Text(taxon.icon)
                .font(.title2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(taxon.name)
                    .font(.subheadline.bold())
                if let conc = taxon.concentration {
                    Text(String(format: "%.1f grains/m³", conc))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(taxon.level.label)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(taxon.level.color)
                .foregroundStyle(taxon.level.textColor)
                .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(taxon.name) : \(taxon.level.label)")
    }

    // MARK: - Recommendations section
    private func recommendationsSection(level: PollenLevel) -> some View {
        let tips = recommendations(for: level)
        return VStack(alignment: .leading, spacing: 10) {
            Label("Recommandations", systemImage: "info.circle")
                .font(.headline)

            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text(tip)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func recommendations(for level: PollenLevel) -> [String] {
        switch level {
        case .unavailable:
            return ["Données non disponibles pour votre commune."]
        case .veryLow, .low:
            return [
                "Aérez tôt le matin (avant 8h) ou tard le soir.",
                "Gardez les fenêtres fermées en milieu de journée.",
                "Rincez vos cheveux après une sortie prolongée."
            ]
        case .moderate:
            return [
                "Prenez votre traitement antihistaminique si prescrit.",
                "Limitez les activités sportives en extérieur.",
                "Portez des lunettes de soleil enveloppantes.",
                "Aérez tôt le matin uniquement."
            ]
        case .high, .veryHigh, .extremelyHigh:
            return [
                "Restez à l'intérieur entre 10h et 17h.",
                "Portez un masque (FFP2) lors des sorties.",
                "Douchez-vous et changez de vêtements après chaque sortie.",
                "Gardez fenêtres et portières fermées en voiture.",
                "Consultez votre médecin si les symptômes s'aggravent."
            ]
        }
    }

    // MARK: - Error view
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Réessayer") {
                locationService.requestLocation()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Réessayer la localisation")
        }
        .padding(.top, 40)
    }

    // MARK: - Refresh
    private func refresh() async {
        locationService.requestLocation()
        if let token = authStore.token,
           authStore.isTokenValid,
           !locationService.inseeCode.isEmpty {
            do {
                try await atmoService.fetchPollen(token: token, codeZone: locationService.inseeCode)
            } catch is AuthError {
                // Token expired or invalid — force logout
                authStore.logout()
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthStore())
        .environmentObject(AtmoService())
        .environmentObject(LocationService())
}
