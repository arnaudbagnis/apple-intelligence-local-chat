import Foundation

// MARK: - Security Policy
struct SecurityPolicy {
    let allowlistPrefixes: [String] = ["ls", "pwd", "echo", "cat", "find", "grep", "whoami", "sw_vers", "date"]
    let denylistTokens: [String] = ["rm", "sudo", "mv", "chown", "chmod", "wget", "curl", "nc", "bash", "sh", "zsh"]

    func evaluate(command: String) throws {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Check deny tokens (very strict)
        for token in denylistTokens {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: token))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)) != nil {
                 throw AgentOrchestratorError.policyViolation("Command contains forbidden token: \(token)")
            }
        }
        
        // 2. Check allowlist (disabled - "open bar")
        // let baseCommand = trimmed.components(separatedBy: " ").first ?? ""
        // if !allowlistPrefixes.contains(baseCommand) {
        //     throw AgentOrchestratorError.policyViolation("Command not in allowlist: \(baseCommand)")
        // }
    }
}

// MARK: - Secret Redactor
struct SecretRedactor {
    // Basic regex for Bearer tokens or AWS keys
    private let patterns = [
        "Bearer\\s+[A-Za-z0-9\\-\\._~\\+/]+",
        "AKIA[0-9A-Z]{16}",
        "sk-[a-zA-Z0-9]{32,}"
    ]
    
    func redact(_ input: String) -> String {
        var output = input
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: output.utf16.count)
                output = regex.stringByReplacingMatches(in: output, options: [], range: range, withTemplate: "[REDACTED SECRET]")
            }
        }
        return output
    }
}
