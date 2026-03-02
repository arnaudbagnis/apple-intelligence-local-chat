import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    var isGenerating: Bool
    var onSend: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Message to Apple Intelligence...", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .lineLimit(1...8)
                
                if isGenerating {
                    Button(action: onCancel) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 2)
                    .help("Cancel generation")
                } else {
                    Button(action: {
                        onSend()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.bottom, 2)
                    .keyboardShortcut(.return, modifiers: .command)
                    .help("Send message (⌘↩︎)")
                }
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}
