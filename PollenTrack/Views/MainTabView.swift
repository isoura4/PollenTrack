import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authStore: AuthStore
    @StateObject private var atmoService    = AtmoService()
    @StateObject private var locationService = LocationService()

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Aujourd'hui", systemImage: "leaf.fill")
                }

            ForecastView()
                .tabItem {
                    Label("Prévisions", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gearshape")
                }
        }
        .environmentObject(atmoService)
        .environmentObject(locationService)
        .onAppear {
            locationService.requestLocation()
        }
        .onChange(of: locationService.inseeCode) { _, newCode in
            guard !newCode.isEmpty,
                  let token = authStore.token,
                  authStore.isTokenValid else { return }
            Task {
                do {
                    try await atmoService.fetchPollen(token: token, codeZone: newCode)
                } catch is AuthError {
                    // Token expired or invalid — force logout
                    authStore.logout()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthStore())
}
