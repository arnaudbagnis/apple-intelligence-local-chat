import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var draftText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if let conversation = viewModel.conversation {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(conversation.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: conversation.messages.count) { _ in
                        scrollToBottom(proxy: proxy, conversation: conversation)
                    }
                    .onChange(of: viewModel.currentStreamingMessage?.content) { _ in
                        scrollToBottom(proxy: proxy, conversation: conversation)
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy, conversation: conversation)
                    }
                }
                
                agentStatusView()
                    .padding(.horizontal)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                MessageInputView(
                    text: $draftText,
                    isGenerating: viewModel.isGenerating,
                    onSend: {
                        viewModel.sendMessage(draftText)
                        draftText = ""
                    },
                    onCancel: {
                        viewModel.cancelGeneration()
                    }
                )
            } else {
                Text("Select or create a conversation")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(viewModel.conversation?.title ?? "LocalChat")
        .sheet(isPresented: isAwaitingConfirmation) {
            if case .awaitingConfirmation(let toolCall) = viewModel.orchestrator.state {
                AgentConfirmationSheet(
                    toolCall: toolCall,
                    onApprove: { modifiedCall in
                        viewModel.orchestrator.resolveConfirmation(with: modifiedCall)
                    },
                    onDeny: {
                        viewModel.orchestrator.resolveConfirmation(with: nil)
                    }
                )
            }
        }
    }
    
    private var isAwaitingConfirmation: Binding<Bool> {
        Binding(
            get: {
                if case .awaitingConfirmation = viewModel.orchestrator.state { return true }
                return false
            },
            set: { _ in }
        )
    }
    
    @ViewBuilder
    private func agentStatusView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let notes = viewModel.orchestrator.internalNotes
            if !notes.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(notes.indices, id: \.self) { index in
                                Text(notes[index])
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(index)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: notes.count) { _ in
                        if let lastIndex = notes.indices.last {
                            withAnimation {
                                proxy.scrollTo(lastIndex, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            switch viewModel.orchestrator.state {
            case .planning: 
                ProgressView("Thinking...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .runningTool(let call): 
                ProgressView("Executing tool: \(call.command ?? "")...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .drafting, .critiquing, .finalizing: 
                ProgressView("Response process active...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            default: 
                EmptyView()
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, conversation: Conversation) {
        if let lastMessage = conversation.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}
