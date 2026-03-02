import Foundation
import Combine

@MainActor
class AgentOrchestrator: ObservableObject {
    @Published var state: AgentState = .idle
    @Published var internalNotes: [String] = []
    
    // Dependencies
    private let client: FoundationModelsClient
    private let terminalTool = TerminalTool()
    
    // Settings
    private let maxSteps = 5
    private var currentStep = 0
    private var conversationContext: String = ""
    
    // Continuations for HITL
    private var confirmationContinuation: CheckedContinuation<AgentToolCall?, Never>?
    
    init(client: FoundationModelsClient = FoundationModelsClient.shared) {
        self.client = client
    }
    
    func startRequest(userMessage: String, history: [Message] = []) async {
        self.state = .planning
        self.currentStep = 0
        self.internalNotes.removeAll()
        
        // Build initial context
        var context = ""
        for msg in history.suffix(10) { // Limit history to last 10 messages for token usage
            context += "\(msg.role == .user ? "User" : "Assistant"): \(msg.content)\n\n"
        }
        context += "User: \(userMessage)\n"
        self.conversationContext = context
        
        await runLoop()
    }
    
    private func runLoop() async {
        while currentStep < maxSteps {
            currentStep += 1
            state = .planning
            
            do {
                // 1. Planning Phase
                let prompt = InternalPrompts.planner(context: conversationContext)
                let planJSON = try await client.generateResponse(
                    prompt: prompt,
                    history: [],
                    systemPrompt: "You are a JSON-only response agent. Strictly output valid JSON matching the schema.",
                    temperature: 0.1 // Low temperature for deterministic output
                )
                
                guard let toolCall = parseToolCall(from: planJSON) else {
                    self.internalNotes.append("Failed to parse JSON: \(planJSON). Falling back to basic reasoning.")
                    // Fallback to reasoning pipeline entirely. Break the loop so it responds to the user.
                    await runReasoningPipeline()
                    return
                }
                
                // If the model decides it doesn't need a tool
                if toolCall.action == "no_tool" || toolCall.tool == nil {
                    await runReasoningPipeline()
                    return
                }
                
                // 2. Awaiting Confirmation (HITL)
                state = .awaitingConfirmation(toolCall)
                let approvedToolCall = await waitForUserConfirmation()
                
                guard let finalCall = approvedToolCall else {
                    // User denied tool run
                    conversationContext += "System: The user denied the tool execution.\n"
                    await runReasoningPipeline()
                    return
                }
                
                // 3. Running Tool
                state = .runningTool(finalCall)
                let result = try await terminalTool.execute(arguments: finalCall)
                
                // 4. Inject Result into context and loop
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let resultData = try encoder.encode(result)
                let resultJSON = String(data: resultData, encoding: .utf8) ?? "{}"
                
                conversationContext += "Tool Call Executed: \(finalCall.command ?? "")\n"
                conversationContext += "Tool Result: \(resultJSON)\n"
                internalNotes.append("Tool Execution: \(finalCall.command ?? "") -> Exit \(result.exit_code)")
                
            } catch {
                state = .failed(error as? AgentOrchestratorError ?? .invalidJSON)
                return
            }
        }
        
        // Fallback
        state = .failed(.maxStepsReached)
    }
    
    // MARK: - Hidden Reasoning Pipeline
    private func runReasoningPipeline() async {
        do {
            state = .drafting
            let draftPrompt = InternalPrompts.draft(context: conversationContext)
            let draft = try await client.generateResponse(
                prompt: draftPrompt, history: [], systemPrompt: "You are a helpful assistant.", temperature: 0.7
            )
            internalNotes.append("Draft: \(draft)")
            
            state = .critiquing
            let critiquePrompt = InternalPrompts.critique(draft: draft)
            let critique = try await client.generateResponse(
                prompt: critiquePrompt, history: [], systemPrompt: "You are a strict reviewer.", temperature: 0.3
            )
            internalNotes.append("Critique: \(critique)")
            
            state = .finalizing
            let finalPrompt = InternalPrompts.finalAnswer(draft: draft, critique: critique)
            let final = try await client.generateResponse(
                prompt: finalPrompt, history: [], systemPrompt: "You are the final editor.", temperature: 0.5
            )
            
            state = .completed(final)
        } catch {
            state = .failed(.invalidJSON)
        }
    }
    
    // MARK: - HITL Controllers
    private func waitForUserConfirmation() async -> AgentToolCall? {
        await withCheckedContinuation { continuation in
            self.confirmationContinuation = continuation
        }
    }
    
    func resolveConfirmation(with toolCall: AgentToolCall?) {
        confirmationContinuation?.resume(returning: toolCall)
        confirmationContinuation = nil
    }
    
    // Safe JSON parsing: extract JSON block if wrapped in markdown or text
    private func parseToolCall(from jsonString: String) -> AgentToolCall? {
        var cleaned = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find the first { and last } to extract the JSON object
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            
            if firstBrace < lastBrace {
                cleaned = String(cleaned[firstBrace...lastBrace])
            }
        }
        
        guard let data = cleaned.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AgentToolCall.self, from: data)
    }
    
    func reset() {
        self.state = .idle
        self.internalNotes.removeAll()
        self.currentStep = 0
        self.conversationContext = ""
    }
}
