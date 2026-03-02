import SwiftUI

struct AgentConfirmationSheet: View {
    @State var toolCall: AgentToolCall
    var onApprove: (AgentToolCall) -> Void
    var onDeny: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(.orange)
                    .font(.title)
                Text("System Authorization Request")
                    .font(.headline)
            }
            
            Text("The agent wants to execute the following action:")
                .foregroundColor(.secondary)
            
            Text(toolCall.explain_to_user)
                .italic()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Shell command")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("...", text: Binding(
                    get: { toolCall.command ?? "" },
                    set: { toolCall.command = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .monospaced))
            }
            
            HStack {
                Text("Estimated risk:")
                Text(toolCall.risk?.uppercased() ?? "UNKNOWN")
                    .bold()
                    .foregroundColor(toolCall.risk == "high" ? .red : (toolCall.risk == "medium" ? .orange : .green))
            }
            
            HStack(spacing: 20) {
                Button(role: .cancel) {
                    onDeny()
                    dismiss()
                } label: {
                    Text("Deny (Continue without tool)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button() {
                    onApprove(toolCall)
                    dismiss()
                } label: {
                    Text("Allow and Execute")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(.top, 10)
        }
        .padding(30)
        .frame(minWidth: 450)
    }
}
