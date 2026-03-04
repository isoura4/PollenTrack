import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authStore: AuthStore

    var body: some View {
        Group {
            if authStore.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authStore.isLoggedIn)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthStore())
}
