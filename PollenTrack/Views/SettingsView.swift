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
