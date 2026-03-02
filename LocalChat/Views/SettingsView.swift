import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            Text("LocalChat Settings")
                .font(.headline)
                .padding()
            
            Divider()
            
            Form {
                Section {
                    VStack(alignment: .leading) {
                        Text("System Prompt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("", text: $viewModel.systemPrompt, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                            .help("Base instructions for the Apple Intelligence assistant.")
                    }
                    .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f", viewModel.temperature))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $viewModel.temperature, in: 0.0...1.0, step: 0.1)
                    }
                    .padding(.bottom, 8)
                    
                    Toggle("Enable Streaming", isOn: $viewModel.useStreaming)
                        .help("If enabled, displays the response incrementally (if supported).")
                    
                    Toggle("Force Mock Mode", isOn: $viewModel.useMockMode)
                        .help("If enabled or if the Apple Intelligence API fails, uses mock responses to debug the interface without requiring local downloads.")
                        
                    Toggle("Enable Agent Mode (HITL)", isOn: $viewModel.useAgentMode)
                        .help("If enabled, the model will be able to use tools (like the terminal) with human confirmation.")
                }
                .padding()
            }
            .formStyle(.grouped)
            
            Divider()
            
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 450, height: 400)
    }
}
