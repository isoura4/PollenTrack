import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authStore: AuthStore

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Compte
                Section("Compte") {
                    LabeledContent("Utilisateur", value: authStore.username)
                        .accessibilityLabel("Utilisateur : \(authStore.username)")

                    Button(role: .destructive) {
                        authStore.logout()
                    } label: {
                        Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityLabel("Se déconnecter")
                }

                // MARK: Ressources
                Section("Ressources") {
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

                // MARK: Mentions légales
                Section("Mentions légales") {
                    Text("Données : Atmo France / AASQA — Licence ODbL 1.0")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Réglages")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthStore())
}
