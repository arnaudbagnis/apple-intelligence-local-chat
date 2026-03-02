import Foundation
import SwiftData
import Combine
import os

@MainActor
class ConversationsListViewModel: ObservableObject {
    private var modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.localchat", category: "ConversationsListViewModel")
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createConversation() -> Conversation {
        logger.info("Creating a new conversation")
        let newConv = Conversation()
        modelContext.insert(newConv)
        save()
        return newConv
    }
    
    func delete(conversation: Conversation) {
        logger.info("Deleting conversation")
        modelContext.delete(conversation)
        save()
    }
    
    func rename(conversation: Conversation, newTitle: String) {
        logger.info("Renaming conversation to \(newTitle)")
        conversation.title = newTitle
        save()
    }
    
    private func save() {
        do {
            try modelContext.save()
            logger.debug("Successfully saved conversation changes")
        } catch {
            logger.error("Failed to save context: \(error)")
            print("Failed to save context: \(error)")
        }
    }
}
