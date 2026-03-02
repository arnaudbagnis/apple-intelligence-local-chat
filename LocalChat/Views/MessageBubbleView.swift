import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    
    @State private var showThoughts = false
    
    var isUser: Bool {
        message.role == .user
    }
    
    private var parsedNotes: [String]? {
        guard let metadata = message.internalMetadata,
              !metadata.isEmpty,
              let data = metadata.data(using: .utf8),
              let notes = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return notes
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                
                if !isUser, let notes = parsedNotes, !notes.isEmpty {
                    DisclosureGroup("Agent Thoughts", isExpanded: $showThoughts) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(notes.indices, id: \.self) { index in
                                Text(notes[index])
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(6)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .padding(.bottom, 4)
                }
                
                Text(message.content)
                    .padding(12)
                    .background(isUser ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                    .foregroundColor(isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .textSelection(.enabled)
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
