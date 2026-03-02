import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var listViewModel: ConversationsListViewModel
    @StateObject private var settings: SettingsViewModel
    @StateObject private var chatViewModel: ChatViewModel
    
    @State private var selectedConversation: Conversation?
    
    // Check available status once or reactively. Here we use the shared client's sync property.
    let isModelAvailable = FoundationModelsClient.shared.isModelAvailable
    
    init(modelContext: ModelContext) {
        let lvModel = ConversationsListViewModel(modelContext: modelContext)
        let sModel = SettingsViewModel()
        
        _listViewModel = StateObject(wrappedValue: lvModel)
        _settings = StateObject(wrappedValue: sModel)
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(modelContext: modelContext, settings: sModel))
    }
    
    var body: some View {
        if isModelAvailable {
            NavigationSplitView {
                SidebarView(
                    listViewModel: listViewModel,
                    settingsViewModel: settings,
                    selectedConversation: $selectedConversation
                )
            } detail: {
                ChatView(viewModel: chatViewModel)
            }
            .onChange(of: selectedConversation) { newValue in
                chatViewModel.setConversation(newValue)
            }
        } else {
            ErrorStateView()
        }
    }
}
