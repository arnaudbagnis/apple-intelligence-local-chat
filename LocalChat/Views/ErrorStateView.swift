import SwiftUI

struct ErrorStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Apple Intelligence Not Available")
                .font(.title)
                .bold()
            
            Text("The LocalChat application requires the FoundationModels framework on this device.\nMake sure you have a compatible Mac and that Apple Intelligence is enabled in system settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 400)
            
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
