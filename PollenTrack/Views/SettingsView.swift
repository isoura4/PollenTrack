import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authStore: AuthStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: Compte
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Compte", systemImage: "person.circle")
                            .font(.headline)

                        LabeledContent("Utilisateur", value: authStore.username)
                            .accessibilityLabel("Utilisateur : \(authStore.username)")

                        Button(role: .destructive) {
                            authStore.logout()
                        } label: {
                            Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .accessibilityLabel("Se déconnecter")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 20)

                    // MARK: Ressources
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Ressources", systemImage: "book")
                            .font(.headline)

                        if let atmoURL = URL(string: "https://www.atmo-france.org/article/reseau-national-surveillance-aerobiologique") {
                            Link(destination: atmoURL) {
                                Label("Documentation pollen Atmo France", systemImage: "doc.text")
                            }
                            .accessibilityLabel("Documentation pollen Atmo France")
                        }

                        if let swaggerURL = URL(string: "https://admindata.atmo-france.org/api/swagger/") {
                            Link(destination: swaggerURL) {
                                Label("Documentation API Swagger", systemImage: "server.rack")
                            }
                            .accessibilityLabel("Documentation API Swagger")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 20)

                    // MARK: Mentions légales
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mentions légales", systemImage: "info.circle")
                            .font(.headline)

                        Text("Données : Atmo France / AASQA — Licence ODbL 1.0")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 20)

                    // MARK: Confidentialité
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Confidentialité", systemImage: "lock.shield")
                            .font(.headline)

                        privacyRow(
                            icon: "location.fill",
                            title: "Localisation GPS",
                            detail: "Envoyée uniquement à api-adresse.data.gouv.fr (API gouvernementale française) pour obtenir le code INSEE de votre commune. Désactivable en utilisant le code postal."
                        )

                        privacyRow(
                            icon: "envelope",
                            title: "Code postal",
                            detail: "Envoyé uniquement à geo.api.gouv.fr (API gouvernementale française). Aucune coordonnée GPS n'est transmise."
                        )

                        privacyRow(
                            icon: "leaf",
                            title: "Données pollen",
                            detail: "Récupérées depuis admindata.atmo-france.org avec votre code INSEE. Aucune donnée personnelle n'est partagée."
                        )

                        privacyRow(
                            icon: "hand.raised.fill",
                            title: "Aucun tiers",
                            detail: "Pas de traqueur, pas d'analytics, pas de publicité. Toutes les données restent sur votre appareil."
                        )
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 20)
                }
                .padding()
            }
            .navigationTitle("Réglages")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthStore())
}

// MARK: - Privacy row helper
private extension SettingsView {
    func privacyRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
