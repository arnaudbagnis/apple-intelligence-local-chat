import Foundation

// MARK: - State Machine
enum AgentState: Equatable {
    case idle
    case planning
    case drafting
    case critiquing
    case finalizing
    case awaitingConfirmation(AgentToolCall)
    case runningTool(AgentToolCall)
    case completed(String) // Final Answer
    case failed(AgentOrchestratorError)
    
    static func == (lhs: AgentState, rhs: AgentState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.planning, .planning), (.drafting, .drafting),
             (.critiquing, .critiquing), (.finalizing, .finalizing): return true
        case (.awaitingConfirmation(let a), .awaitingConfirmation(let b)): return a.id == b.id
        case (.runningTool(let a), .runningTool(let b)): return a.id == b.id
        case (.completed(let a), .completed(let b)): return a == b
        case (.failed, .failed): return true // Simplified for Equatable
        default: return false
        }
    }
}

enum AgentOrchestratorError: Error, LocalizedError {
    case maxStepsReached
    case invalidJSON
    case userDenied
    case policyViolation(String)
    case toolExecutionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .maxStepsReached: return "Nombre d'étapes maximum atteint."
        case .invalidJSON: return "Le modèle a renvoyé un format JSON invalide."
        case .userDenied: return "L'utilisateur a refusé l'exécution de l'outil."
        case .policyViolation(let reason): return "Violation de sécurité : \(reason)"
        case .toolExecutionFailed(let reason): return "Erreur d'outil : \(reason)"
        }
    }
}

// MARK: - Tool Calling DTOs
struct AgentToolCall: Codable, Identifiable {
    let action: String // "tool_call" ou "no_tool"
    let tool: String?
    let id: String
    let explain_to_user: String
    var command: String?
    let cwd: String?
    let risk: String? // "low", "medium", "high"
    let needs_confirmation: Bool?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        action = try container.decode(String.self, forKey: .action)
        tool = try container.decodeIfPresent(String.self, forKey: .tool)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        explain_to_user = try container.decodeIfPresent(String.self, forKey: .explain_to_user) ?? ""
        command = try container.decodeIfPresent(String.self, forKey: .command)
        cwd = try container.decodeIfPresent(String.self, forKey: .cwd)
        risk = try container.decodeIfPresent(String.self, forKey: .risk)
        needs_confirmation = try container.decodeIfPresent(Bool.self, forKey: .needs_confirmation)
    }
}

struct AgentToolResult: Codable {
    let action: String = "tool_result"
    let id: String
    let exit_code: Int
    let stdout: String
    let stderr: String
    let duration_ms: Int
    let truncated: Bool
}

// MARK: - Tool Protocol
protocol AgentTool {
    var name: String { get }
    var description: String { get }
    func execute(arguments: AgentToolCall) async throws -> AgentToolResult
}
