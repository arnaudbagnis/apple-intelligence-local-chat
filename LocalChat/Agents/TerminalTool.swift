import Foundation

// MARK: - Terminal Tool
class TerminalTool: AgentTool {
    let name = "terminal.run"
    let description = "Exécute une commande shell sécurisée. Doit être confirmée par l'utilisateur."
    
    private let policy = SecurityPolicy()
    private let redactor = SecretRedactor()
    private let maxOutputLength = 5000
    
    func execute(arguments: AgentToolCall) async throws -> AgentToolResult {
        guard let commandString = arguments.command else {
            throw AgentOrchestratorError.toolExecutionFailed("No command provided")
        }
        
        try policy.evaluate(command: commandString)
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh") // using sh -c safely due to policy
            process.arguments = ["-c", commandString]
            
            if let cwd = arguments.cwd {
                process.currentDirectoryURL = URL(fileURLWithPath: cwd)
            }
            
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            
            let startTime = Date()
            
            process.terminationHandler = { [weak self] proc in
                guard let self = self else { return }
                
                let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                
                var outStr = String(decoding: outData, as: UTF8.self)
                var errStr = String(decoding: errData, as: UTF8.self)
                
                outStr = self.redactor.redact(outStr)
                errStr = self.redactor.redact(errStr)
                
                var truncated = false
                if outStr.count > self.maxOutputLength {
                    outStr = String(outStr.prefix(self.maxOutputLength)) + "\n...[TRUNCATED]"
                    truncated = true
                }
                
                let duration = Int(Date().timeIntervalSince(startTime) * 1000)
                
                let result = AgentToolResult(
                    id: arguments.id,
                    exit_code: Int(proc.terminationStatus),
                    stdout: outStr,
                    stderr: errStr,
                    duration_ms: duration,
                    truncated: truncated
                )
                continuation.resume(returning: result)
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: AgentOrchestratorError.toolExecutionFailed(error.localizedDescription))
            }
        }
    }
}
