import SwiftUI
import SwiftData

@main
struct LocalChatApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Conversation.self,
                Message.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            do {
                container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                print("Failed to load ModelContainer, attempting to delete the old store: \(error)")
                let fileManager = FileManager.default
                if let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                    let storeURL = applicationSupportDirectory.appendingPathComponent("default.store")
                    let shmURL = applicationSupportDirectory.appendingPathComponent("default.store-shm")
                    let walURL = applicationSupportDirectory.appendingPathComponent("default.store-wal")
                    
                    try? fileManager.removeItem(at: storeURL)
                    try? fileManager.removeItem(at: shmURL)
                    try? fileManager.removeItem(at: walURL)
                }
                
                // Retry creating the container after wiping the database
                container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(modelContext: container.mainContext)
        }
        .modelContainer(container)
        .defaultSize(width: 900, height: 600)
    }
}
