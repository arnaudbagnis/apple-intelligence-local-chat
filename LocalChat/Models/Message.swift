import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

@Model
final class Message {
    var id: UUID
    var content: String
    private var roleRawValue: String
    var createdAt: Date
    
    var conversation: Conversation?
    var internalMetadata: String?
    
    @Transient
    var role: MessageRole {
        get { MessageRole(rawValue: roleRawValue) ?? .user }
        set { roleRawValue = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), content: String, role: MessageRole, createdAt: Date = Date(), internalMetadata: String? = nil) {
        self.id = id
        self.content = content
        self.roleRawValue = role.rawValue
        self.createdAt = createdAt
    }
}
