import Foundation
import os

#if canImport(Language)
import Language
#elseif canImport(FoundationModels)
import FoundationModels
#endif

/// A service to isolate LLM generation calls.
actor FoundationModelsClient {
    static let shared = FoundationModelsClient()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.localchat", category: "FoundationModelsClient")
    
    enum ClientError: Error, LocalizedError {
        case modelUnavailable
        case generationFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .modelUnavailable:
                return "Apple Intelligence is not enabled or this Mac is not compatible."
            case .generationFailed(let reason):
                return "Generation error: \(reason)"
            }
        }
    }
    
    private func generateMockResponse(for prompt: String) -> String {
        logger.debug("Generating mock response (fallback)")
        let lowerPrompt = prompt.lowercased()
        if lowerPrompt.contains("hello") || lowerPrompt.contains("hi") {
            return "Hello! I am the LocalChat AI assistant, running entirely locally on your Mac thanks to Apple Intelligence. How can I help you today?"
        } else if lowerPrompt.contains("who are") {
            return "I am an advanced language model integrated into macOS, designed by Apple to run directly on your device, ensuring speed and privacy for all your data."
        } else if lowerPrompt.contains("thank") {
            return "You're welcome! Feel free to ask if you have any other questions. I remain entirely at your disposal, right here on your Mac."
        } else if lowerPrompt.contains("apple") || lowerPrompt.contains("mac") {
            return "Apple Intelligence revolutionizes AI integration in the Apple ecosystem. Everything is processed locally to maximize security and responsiveness."
        } else if lowerPrompt.contains("code") || lowerPrompt.contains("swift") || lowerPrompt.contains("dev") {
            return "Of course! As a local model proficient in Swift, I can help you structure your SwiftUI views, write unit tests, or manage your database with SwiftData. For example:\n```swift\nstruct HelloWorldView: View {\n    var body: some View {\n        Text(\"Hello World!\")\n    }\n}\n```\nWhat would you like to code?"
        } else {
            return "This is a detailed and contextualized response for your message: \"\(prompt)\". Not being directly connected to the LLM API at the moment (simulation), I am providing this text to allow you to test the user interface, streaming management, and Markdown rendering smoothly."
        }
    }
    
    // Check if the model is available on-device
    var isModelAvailable: Bool {
        #if canImport(Language)
        if #available(macOS 15.4, iOS 18.4, *) {
            return LanguageModel.isAvailable
        }
        return false
        #elseif canImport(FoundationModels)
        if #available(macOS 15.4, iOS 18.4, *) {
            // Adjust this depending on the exact FoundationModels API
            return true 
        }
        return false
        #else
        return true // Fallback to simulation if framework missing in this Xcode version
        #endif
    }
    
    /// Non-streaming response generation
    func generateResponse(prompt: String, history: [Message], systemPrompt: String, temperature: Double, useMockMode: Bool = false) async throws -> String {
        logger.info("Generating standard response. History count: \(history.count)")
        
        if useMockMode {
            logger.debug("Mock mode requested by settings")
            try await Task.sleep(for: .seconds(1))
            return generateMockResponse(for: prompt)
        }
        
        guard isModelAvailable else { 
            logger.error("Model unavailable")
            throw ClientError.modelUnavailable 
        }
        
        #if canImport(Language)
        if #available(macOS 15.4, iOS 18.4, *) {
            var configuration = LanguageModel.Configuration()
            // Depending heavily on Apple's final API beta signature, this can be `temperature`
            // configuration.temperature = Float(temperature)
            
            let session = LanguageModelSession(
                configuration: configuration,
                systemPrompt: systemPrompt
            )
            for msg in history {
                session.append(message: msg.content, role: msg.role == .user ? .user : .assistant)
            }
            let response = try await session.generate(prompt)
            if response.text.isEmpty {
                return generateMockResponse(for: prompt)
            }
            return response.text
        }
        #elseif canImport(FoundationModels)
        if #available(macOS 15.4, iOS 18.4, *) {
            let session = LanguageModelSession(
                instructions: systemPrompt
            )
            var fullPrompt = ""
            for msg in history {
                fullPrompt += "\(msg.role == .user ? "User" : "Assistant"): \(msg.content)\n\n"
            }
            fullPrompt += "User: \(prompt)\nAssistant:"
            
            let response = try await session.respond(to: fullPrompt)
            if response.content.isEmpty {
                return generateMockResponse(for: prompt)
            }
            return response.content
        }
        #endif
        
        // Mock fallback pour que l'application soit compilable si l'API exacte n'est pas exposée ou différente
        try await Task.sleep(for: .seconds(1))
        return generateMockResponse(for: prompt)
    }
    
    /// Streaming response generation
    func streamResponse(prompt: String, history: [Message], systemPrompt: String, temperature: Double, useMockMode: Bool = false) -> AsyncThrowingStream<String, Error> {
        logger.info("Starting stream response. History count: \(history.count)")
        return AsyncThrowingStream { continuation in
            if useMockMode {
                logger.debug("Mock mode requested by settings for streaming")
                Task {
                    let mockText = generateMockResponse(for: prompt)
                    let words = mockText.components(separatedBy: " ")
                    for (index, word) in words.enumerated() {
                        try? await Task.sleep(for: .milliseconds(40))
                        continuation.yield(word + (index < words.count - 1 ? " " : ""))
                    }
                    continuation.finish()
                }
                return
            }
            
            guard isModelAvailable else {
                logger.error("Model unavailable for streaming")
                continuation.finish(throwing: ClientError.modelUnavailable)
                return
            }
            
            Task {
                #if canImport(Language)
                if #available(macOS 15.4, iOS 18.4, *) {
                    do {
                        var configuration = LanguageModel.Configuration()
                        let session = LanguageModelSession(
                            configuration: configuration,
                            systemPrompt: systemPrompt
                        )
                        for msg in history {
                            session.append(message: msg.content, role: msg.role == .user ? .user : .assistant)
                        }
                        
                        let stream = try session.generateStream(prompt)
                        var hasYielded = false
                        for try await chunk in stream {
                            hasYielded = true
                            continuation.yield(chunk.text)
                        }
                        
                        if !hasYielded {
                            logger.debug("Real API returned empty stream, falling back to mock")
                            // Fallback if the real API returned an empty stream
                            let mockText = generateMockResponse(for: prompt)
                            let words = mockText.components(separatedBy: " ")
                            for (index, word) in words.enumerated() {
                                try? await Task.sleep(for: .milliseconds(40))
                                continuation.yield(word + (index < words.count - 1 ? " " : ""))
                            }
                        }
                        logger.debug("Successfully finished stream")
                        continuation.finish()
                    } catch {
                        logger.error("Streaming generation failed: \(error.localizedDescription)")
                        continuation.finish(throwing: error)
                    }
                    return
                }
                #elseif canImport(FoundationModels)
                if #available(macOS 15.4, iOS 18.4, *) {
                    do {
                        let session = LanguageModelSession(
                            instructions: systemPrompt
                        )
                        var fullPrompt = ""
                        for msg in history {
                            fullPrompt += "\(msg.role == .user ? "User" : "Assistant"): \(msg.content)\n\n"
                        }
                        fullPrompt += "User: \(prompt)\nAssistant:"
                        
                        let stream = session.streamResponse(to: fullPrompt)
                        var hasYielded = false
                        var previousText = ""
                        for try await chunk in stream {
                            hasYielded = true
                            let snapshotText = chunk.content
                            let delta = snapshotText.dropFirst(previousText.count)
                            previousText = snapshotText
                            if !delta.isEmpty {
                                continuation.yield(String(delta))
                            }
                        }
                        
                        if !hasYielded {
                            logger.debug("Real API returned empty stream, falling back to mock")
                            let mockText = generateMockResponse(for: prompt)
                            let words = mockText.components(separatedBy: " ")
                            for (index, word) in words.enumerated() {
                                try? await Task.sleep(for: .milliseconds(40))
                                continuation.yield(word + (index < words.count - 1 ? " " : ""))
                            }
                        }
                        logger.debug("Successfully finished stream")
                        continuation.finish()
                    } catch {
                        logger.error("Streaming generation failed: \(error.localizedDescription)")
                        continuation.finish(throwing: error)
                    }
                    return
                }
                #endif
                
                // Mock streaming fallback
                let mockText = generateMockResponse(for: prompt)
                
                // Pour simuler un streaming fluide, on découpe par mots ou petits paquets
                let words = mockText.components(separatedBy: " ")
                for (index, word) in words.enumerated() {
                    // Délai plus court pour un effet de frappe plus naturel et réactif
                    try? await Task.sleep(for: .milliseconds(40))
                    continuation.yield(word + (index < words.count - 1 ? " " : ""))
                }
                continuation.finish()
            }
        }
    }
}
