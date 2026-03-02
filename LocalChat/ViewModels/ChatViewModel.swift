import Foundation
import SwiftData
import os
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversation: Conversation?
    @Published var isGenerating: Bool = false
    @Published var currentStreamingMessage: Message?
    @Published var errorMessage: String?
    
    @Published var orchestrator: AgentOrchestrator
    
    private var settings: SettingsViewModel
    private var generationTask: Task<Void, Never>?
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.localchat", category: "ChatViewModel")
    
    init(modelContext: ModelContext, settings: SettingsViewModel) {
        self.modelContext = modelContext
        self.settings = settings
        self.orchestrator = AgentOrchestrator()
        
        // Forward orchestrator state changes to the view
        self.orchestrator.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
    
    func setConversation(_ conversation: Conversation?) {
        logger.info("Setting conversation: \(conversation?.id.uuidString ?? "nil")")
        self.conversation = conversation
        cancelGeneration()
    }
    
    func sendMessage(_ content: String) {
        guard let conversation = conversation else { return }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        logger.info("Sending message: \(trimmed.prefix(20))...")
        let userMessage = Message(content: trimmed, role: .user)
        conversation.messages.append(userMessage)
        save()
        
        if settings.useAgentMode {
            generateAgentResponse(for: trimmed)
        } else {
            generateAssistantResponse(for: trimmed)
        }
    }
    
    private func generateAgentResponse(for prompt: String) {
        guard let conversation = conversation else { return }
        logger.info("Generating agent response for prompt")
        isGenerating = true
        errorMessage = nil
        
        let history = Array(conversation.messages.dropLast())
        
        generationTask?.cancel()
        generationTask = Task {
            await orchestrator.startRequest(userMessage: prompt, history: history)
            
            if !Task.isCancelled {
                if case .completed(let finalAnswer) = orchestrator.state {
                    
                    var metadata: String?
                    if !orchestrator.internalNotes.isEmpty {
                        let jsonNotes = try? JSONSerialization.data(withJSONObject: orchestrator.internalNotes)
                        metadata = String(data: jsonNotes ?? Data(), encoding: .utf8)
                    }
                    
                    let assistantMessage = Message(content: finalAnswer, role: .assistant, internalMetadata: metadata)
                    
                    conversation.messages.append(assistantMessage)
                    save()
                } else if case .failed(let error) = orchestrator.state {
                    logger.error("Agent failed: \(error.localizedDescription)")
                    let errorMsg = Message(content: "Agent Error: \(error.localizedDescription)", role: .assistant)
                    conversation.messages.append(errorMsg)
                    save()
                }
                
                orchestrator.reset()
                isGenerating = false
            }
        }
    }
    
    private func generateAssistantResponse(for prompt: String) {
        guard let conversation = conversation else { return }
        
        logger.info("Generating assistant response for prompt of length \(prompt.count)")
        isGenerating = true
        errorMessage = nil
        
        // Exclude the recently added user message from the history context if the API expects just prior history.
        // Or include it if the API expects the full context including the current prompt.
        // We will pass the full history up to the message before.
        let history = Array(conversation.messages.dropLast())
        
        generationTask?.cancel()
        
        generationTask = Task {
            do {
                if settings.useStreaming {
                    let assistantMessage = Message(content: "", role: .assistant)
                    conversation.messages.append(assistantMessage)
                    self.currentStreamingMessage = assistantMessage
                    save()
                    
                    let stream = await FoundationModelsClient.shared.streamResponse(
                        prompt: prompt,
                        history: history,
                        systemPrompt: settings.systemPrompt,
                        temperature: settings.temperature,
                        useMockMode: settings.useMockMode
                    )
                    
                    for try await chunk in stream {
                        if Task.isCancelled { break }
                        assistantMessage.content += chunk
                    }
                    save()
                } else {
                    let response = try await FoundationModelsClient.shared.generateResponse(
                        prompt: prompt,
                        history: history,
                        systemPrompt: settings.systemPrompt,
                        temperature: settings.temperature,
                        useMockMode: settings.useMockMode
                    )
                    
                    if !Task.isCancelled {
                        logger.info("Generation successful")
                        let assistantMessage = Message(content: response, role: .assistant)
                        conversation.messages.append(assistantMessage)
                        save()
                    }
                }
            } catch {
                logger.error("Failed to generate response: \(error.localizedDescription)")
                if !Task.isCancelled {
                    let errorMsg = Message(content: "Error: \(error.localizedDescription)", role: .assistant)
                    conversation.messages.append(errorMsg)
                    save()
                }
            }
            
            isGenerating = false
            currentStreamingMessage = nil
        }
    }
    
    func cancelGeneration() {
        if generationTask != nil {
            logger.info("Cancelling generation")
        }
        generationTask?.cancel()
        isGenerating = false
        currentStreamingMessage = nil
    }
    
    private func save() {
        do {
            try modelContext.save()
            logger.debug("Successfully saved model context")
        } catch {
            logger.error("Failed to save context: \(error)")
            print("Failed to save context: \(error)")
        }
    }
}
