import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.createdAt, order: .reverse) private var conversations: [Conversation]
    
    @ObservedObject var listViewModel: ConversationsListViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    @Binding var selectedConversation: Conversation?
    
    @State private var showSettings = false
    
    var body: some View {
        List(selection: $selectedConversation) {
            ForEach(conversations) { conversation in
                NavigationLink(value: conversation) {
                    VStack(alignment: .leading) {
                        Text(conversation.title)
                            .lineLimit(1)
                            .font(.headline)
                        if let lastMessage = conversation.messages.last {
                            Text(lastMessage.content)
                                .lineLimit(1)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        if selectedConversation == conversation {
                            selectedConversation = nil
                        }
                        listViewModel.delete(conversation: conversation)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let conv = conversations[index]
                    if selectedConversation == conv {
                        selectedConversation = nil
                    }
                    listViewModel.delete(conversation: conv)
                }
            }
        }
        .navigationTitle("Conversations")
        .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    selectedConversation = listViewModel.createConversation()
                }) {
                    Label("New conversation", systemImage: "square.and.pencil")
                }
                .help("Create a new conversation")
            }
            ToolbarItem(placement: .automatic) {
                Button(action: { showSettings = true }) {
                    Label("Settings", systemImage: "gearshape")
                }
                .help("Application settings")
            }
        }
        .sheet(isPresented: $showSettings) {
             SettingsView(viewModel: settingsViewModel)
        }
    }
}
