import SwiftUI
import Combine
import os

class SettingsViewModel: ObservableObject {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.localchat", category: "SettingsViewModel")
    @Published var systemPrompt: String {
        didSet { 
            logger.debug("System prompt changed")
            UserDefaults.standard.set(self.systemPrompt, forKey: "systemPrompt") 
        }
    }
    
    @Published var temperature: Double {
        didSet { 
            logger.debug("Temperature changed to \(self.temperature)")
            UserDefaults.standard.set(self.temperature, forKey: "modelTemperature") 
        }
    }
    
    @Published var useStreaming: Bool {
        didSet { 
            logger.debug("Use streaming changed to \(self.useStreaming)")
            UserDefaults.standard.set(self.useStreaming, forKey: "useStreaming") 
        }
    }
    
    @Published var useMockMode: Bool {
        didSet { 
            logger.debug("Use mock mode changed to \(self.useMockMode)")
            UserDefaults.standard.set(self.useMockMode, forKey: "useMockMode") 
        }
    }
    
    @Published var useAgentMode: Bool {
        didSet { 
            logger.debug("Use agent mode changed to \(self.useAgentMode)")
            UserDefaults.standard.set(self.useAgentMode, forKey: "useAgentMode") 
        }
    }
    
    init() {
        self.systemPrompt = UserDefaults.standard.string(forKey: "systemPrompt") ?? "You are a helpful, concise assistant."
        
        if UserDefaults.standard.object(forKey: "modelTemperature") != nil {
            self.temperature = UserDefaults.standard.double(forKey: "modelTemperature")
        } else {
            self.temperature = 0.7
        }
        
        if UserDefaults.standard.object(forKey: "useStreaming") != nil {
            self.useStreaming = UserDefaults.standard.bool(forKey: "useStreaming")
        } else {
            self.useStreaming = true
        }
        
        if UserDefaults.standard.object(forKey: "useMockMode") != nil {
            self.useMockMode = UserDefaults.standard.bool(forKey: "useMockMode")
        } else {
            self.useMockMode = false
        }
        
        if UserDefaults.standard.object(forKey: "useAgentMode") != nil {
            self.useAgentMode = UserDefaults.standard.bool(forKey: "useAgentMode")
        } else {
            self.useAgentMode = false
        }
        logger.info("SettingsViewModel initialized")
    }
}
