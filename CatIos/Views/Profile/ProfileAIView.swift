import SwiftUI

struct ProfileAIView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            OracleHubView(path: $path)
                .navigationDestination(for: UUID.self) { id in
                    PetAIAssistantView(conversationId: id, path: $path)
                }
        }
    }
}

#Preview {
    ProfileAIView()
        .environmentObject(PetManager.shared)
        .environmentObject(AuthSession.shared)
        .environmentObject(AssistantSessionStore.shared)
        .environmentObject(HouseholdSync.shared)
}
