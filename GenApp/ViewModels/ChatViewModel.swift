//
//  ChatViewModel.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var detectedIntent: UserIntent?
    @Published var isBuildingApp = false
    @Published var buildProgress: Double = 0.0
    @Published var buildStatusMessage: String = ""
    @Published var generatedAppDesign: AppDesign?
    @Published var showSavePrompt = false
    @Published var builtApp: GeneratedApp?
    @Published var showAppPreview = false
    
    private let openAIService: OpenAIService
    private let intentService: IntentRecognitionService
    private let appBuilderOrchestrator: AppBuilderOrchestrator
    private let storageService: StorageService?
    private let userId: String?
    let onAppGenerated: ((AppDesign) -> Void)?
    let runtimeService: AppRuntimeService
    
    private static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    init(openAIService: OpenAIService, appBuilderOrchestrator: AppBuilderOrchestrator, storageService: StorageService? = nil, userId: String? = nil, onAppGenerated: ((AppDesign) -> Void)? = nil) {
        self.openAIService = openAIService
        self.appBuilderOrchestrator = appBuilderOrchestrator
        self.storageService = storageService
        self.userId = userId
        self.intentService = IntentRecognitionService()
        self.onAppGenerated = onAppGenerated
        self.runtimeService = appBuilderOrchestrator.runtimeService
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: inputText)
        let messageText = inputText
        messages.append(userMessage)
        appendBackendLog("User prompt received (\(messageText.count) chars)")
        
        inputText = ""
        isLoading = true
        errorMessage = nil
        detectedIntent = nil
        
        Task {
            // First, recognize intent
            let intent = await intentService.recognizeIntent(from: messageText)
            detectedIntent = intent
            appendBackendLog("Intent detected: \(intent.summary)")
            
            switch intent {
            case .buildApp(let description, let requirements):
                // Build app from description
                await buildAppFromDescription(description: description, requirements: requirements)
                
            case .modifyApp(let appId, let changes):
                // Handle app modification
                await handleAppModification(appId: appId, changes: changes)
                
            case .generalChat, .unknown:
                // Regular chat response
                await sendRegularMessage()
            }
            
            isLoading = false
        }
    }
    
    private func buildAppFromDescription(description: String, requirements: [String]) async {
        isBuildingApp = true
        buildProgress = 0.05
        buildStatusMessage = "Analyzing your requirements..."
        appendBackendLog("Starting build pipeline with \(requirements.count) requirements")
        builtApp = nil
        showAppPreview = false
        showSavePrompt = false
        
        // Monitor orchestrator progress
        let progressTask = Task {
            while isBuildingApp {
                await MainActor.run {
                    buildProgress = appBuilderOrchestrator.buildProgress
                    buildStatusMessage = appBuilderOrchestrator.detailedStatus.isEmpty ? 
                        statusForProgress(appBuilderOrchestrator.buildProgress) : 
                        appBuilderOrchestrator.detailedStatus
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
        
        do {
            // Step 1: Generate app design from description
            buildProgress = 0.1
            buildStatusMessage = "Extracting app requirements..."
            await Task.yield()
            
            buildProgress = 0.15
            buildStatusMessage = "Designing app structure with AI..."
            let design = try await intentService.generateAppDesign(from: description, requirements: requirements)
            generatedAppDesign = design
            buildStatusMessage = "App design created ✓"
            appendBackendLog("Design generated: \(design.name) with \(design.rootComponent.children.count) components")
            
            // Step 2: Run full build cycle
            buildProgress = 0.2
            buildStatusMessage = "Starting build process..."
            appendBackendLog("Running local builder orchestration")
            await appBuilderOrchestrator.runFullCycle(design: design, autoDebug: true)
            
            if let generated = appBuilderOrchestrator.generatedApp {
                builtApp = generated
                appendBackendLog("Runtime artifacts ready for preview")
                showAppPreview = true
            } else {
                appendBackendLog("Build completed but runtime artifact missing from orchestrator")
            }
            buildProgress = 1.0
            buildStatusMessage = "Build complete! ✓"
            appendBackendLog("Build finished successfully")
            
            // Step 3: Show save prompt
            showSavePrompt = true
            onAppGenerated?(design)
            
            // Add system message about app creation
            let systemMessage = ChatMessage(
                role: .assistant,
                content: "I've created your app! It's ready to test. Would you like to save it to 'My Creations'?"
            )
            messages.append(systemMessage)
            
        } catch {
            errorMessage = "Failed to build app: \(error.localizedDescription)"
            buildStatusMessage = "Build failed: \(error.localizedDescription)"
            appendBackendLog("Build failed: \(error.localizedDescription)")
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "I encountered an error while building your app: \(error.localizedDescription). Let me try again with a simpler design."
            )
            messages.append(errorMsg)
        }
        
        progressTask.cancel()
        isBuildingApp = false
        buildProgress = 0.0
        buildStatusMessage = ""
    }
    
    private func statusForProgress(_ progress: Double) -> String {
        if progress < 0.2 {
            return "Analyzing requirements..."
        } else if progress < 0.4 {
            return "Designing app structure..."
        } else if progress < 0.6 {
            return "Generating code..."
        } else if progress < 0.8 {
            return "Validating & debugging..."
        } else if progress < 1.0 {
            return "Finalizing..."
        } else {
            return "Complete!"
        }
    }
    
    private func handleAppModification(appId: String?, changes: String) async {
        // For now, treat as regular chat
        appendBackendLog("Modification intent detected (appId: \(appId ?? "n/a")) – falling back to chat")
        await sendRegularMessage()
    }
    
    private func sendRegularMessage() async {
        do {
            appendBackendLog("Generating lightweight response using local AI engine")
            let response = try await openAIService.sendMessage(messages: messages)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
            appendBackendLog("Response delivered to chat")
        } catch {
            errorMessage = error.localizedDescription
            appendBackendLog("Response generation failed: \(error.localizedDescription)")
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "I'm sorry, I encountered an error: \(error.localizedDescription)"
            )
            messages.append(errorMsg)
        }
    }
    
    func saveGeneratedApp() {
        guard let design = generatedAppDesign else { return }
        
        // Reuse built artifact if available to avoid redundant generation
        let generatedApp: GeneratedApp
        if let builtApp = builtApp {
            generatedApp = builtApp
        } else {
            let codeGenerator = CodeGeneratorService()
            generatedApp = codeGenerator.generateApp(from: design)
            self.builtApp = generatedApp
        }
        
        // Save to storage if available
        if let storageService = storageService, let userId = userId {
            let appContent = """
            {
                "design": \(try! JSONEncoder().encode(design).base64EncodedString()),
                "html": "\(generatedApp.html.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))",
                "css": "\(generatedApp.css.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))",
                "javascript": "\(generatedApp.javascript.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))"
            }
            """
            
            let creation = Creation(
                userId: userId,
                title: design.name,
                description: design.description,
                type: .app,
                content: appContent
            )
            
            storageService.saveCreation(creation)
        }
        
        // Call the callback if provided
        onAppGenerated?(design)
        
        showSavePrompt = false
        generatedAppDesign = nil
        appendBackendLog("Saved \(design.name) to local storage")
        
        // Add confirmation message
        let confirmMessage = ChatMessage(
            role: .assistant,
            content: "✅ Your app '\(design.name)' has been saved to 'My Creations'! You can now test it from the Storage tab."
        )
        messages.append(confirmMessage)
    }
    
    func dismissSavePrompt() {
        showSavePrompt = false
        generatedAppDesign = nil
    }
    
    func openPreview() {
        guard builtApp != nil else { return }
        showAppPreview = true
        appendBackendLog("Opening local runtime preview")
    }
    
    func dismissPreview() {
        showAppPreview = false
    }
    
    func clearChat() {
        messages.removeAll()
        detectedIntent = nil
        generatedAppDesign = nil
        showSavePrompt = false
        builtApp = nil
        showAppPreview = false
        appendBackendLog("Backend logs reset")
    }
    
    private func appendBackendLog(_ text: String) {
        let timestamp = ChatViewModel.logFormatter.string(from: Date())
        let content = "[\(timestamp)] \(text)"
        let logMessage = ChatMessage(role: .log, content: content)
        messages.append(logMessage)
    }
}

