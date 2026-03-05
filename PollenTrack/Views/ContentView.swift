import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authStore: AuthStore

    var body: some View {
        Group {
            if authStore.isLoggedIn && authStore.isTokenValid {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authStore.isLoggedIn && authStore.isTokenValid)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthStore())
}
