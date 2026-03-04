import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authStore: AuthStore

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let gradientColors = [Color(hex: "#50F0E6"), Color(hex: "#50CCAA")]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "wind")
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)

                        Text("PollenTrack")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text("Suivez l'indice pollen en temps réel")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)

                    // Login form
                    VStack(spacing: 16) {
                        TextField("Nom d'utilisateur", text: $username)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemBackground).opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityLabel("Nom d'utilisateur")

                        SecureField("Mot de passe", text: $password)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemBackground).opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Mot de passe")

                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                        }

                        Button {
                            Task { await performLogin() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Se connecter")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#50CCAA"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isLoading || username.isEmpty || password.isEmpty)
                        .accessibilityLabel("Se connecter")
                    }
                    .padding(.horizontal, 24)

                    // Create account link
                    VStack(spacing: 8) {
                        Text("Pas encore de compte ?")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))

                        Link("Créer un compte sur Atmo France",
                             destination: URL(string: "https://admindata.atmo-france.org")!)
                            .font(.footnote.bold())
                            .foregroundStyle(.white)
                            .accessibilityLabel("Créer un compte sur Atmo France")
                    }

                    Spacer(minLength: 40)

                    // Footer
                    Text("Licence ODbL — Source : Atmo France / AASQA")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Login action
    private func performLogin() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authStore.login(username: username, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthStore())
}
