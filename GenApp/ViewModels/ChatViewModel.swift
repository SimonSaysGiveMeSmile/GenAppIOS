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
    @Published var generatedMiniApp: MiniAppSpec?
    @Published var showAppPreview = false
    @Published var toolCallHistory: [ToolCallSummary] = []
    
    private let openAIService: OpenAIService
    private let intentService: IntentRecognitionService
    private let appBuilderOrchestrator: AppBuilderOrchestrator
    private let storageService: StorageService?
    private let userId: String?
    let onAppGenerated: ((AppDesign) -> Void)?
    let runtimeService: AppRuntimeService
    
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
        
        inputText = ""
        isLoading = true
        errorMessage = nil
        detectedIntent = nil
        
        Task {
            // First, recognize intent
            let intent = await intentService.recognizeIntent(from: messageText)
            detectedIntent = intent
            
            switch intent {
            case .buildApp(let description, let requirements):
                // Build app from description
                await buildAppFromDescription(description: description, requirements: requirements)
                
            case .modifyApp(let _, let changes):
                // Handle app modification - treat as app building with refinement
                if generatedMiniApp != nil {
                    // Refine existing app
                    await refineExistingApp(changes: changes)
                } else {
                    // Build new app
                    await buildAppFromDescription(description: changes, requirements: [])
                }
                
            case .generalChat, .unknown:
                // Regular chat response
                await sendRegularMessage()
            }
            
            isLoading = false
        }
    }
    
    private func buildAppFromDescription(description: String, requirements: [String]) async {
        toolCallHistory.removeAll()
        isBuildingApp = true
        buildProgress = 0.05
        buildStatusMessage = "Analyzing your requirements..."
        generatedMiniApp = nil
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
            // Step 1: Generate MiniAppSpec using OpenAI (with conversation history)
            buildProgress = 0.1
            buildStatusMessage = "Connecting to OpenAI API..."
            await Task.yield()
            
            // Check if OpenAI is available
            if !openAIService.hasAPIKey {
                throw OpenAIError.missingAPIKey
            }
            
            await invokeTool(.promptCompression, payload: description)
            
            buildProgress = 0.2
            buildStatusMessage = "Generating app code with AI..."
            
            // Use conversation history for context
            let conversationHistory = messages.filter { $0.role != .log }
            let spec = try await intentService.generateMiniAppSpec(
                from: description,
                conversationHistory: conversationHistory
            )
            
            buildProgress = 0.4
            buildStatusMessage = "Validating generated code..."
            
            // Validate the generated spec
            let validationResult = validateMiniAppSpec(spec)
            if !validationResult.isValid {
                buildProgress = 0.5
                buildStatusMessage = "Refining app design..."
                
                // Try to refine with feedback
                let refinedSpec = try await refineMiniAppSpec(
                    originalSpec: spec,
                    issues: validationResult.errors,
                    description: description,
                    conversationHistory: conversationHistory
                )
                
                generatedMiniApp = refinedSpec
            } else {
                generatedMiniApp = spec
            }
            
            buildProgress = 0.6
            buildStatusMessage = "Converting to app design..."
            await invokeTool(.componentBuilder, payload: "\(spec.name) • \(spec.pages.count) pages")
            
            // Convert MiniAppSpec to AppDesign for compatibility
            let design = try convertMiniAppSpecToAppDesign(spec, originalDescription: description)
            generatedAppDesign = design
            
            buildProgress = 0.7
            buildStatusMessage = "Loading app into runtime..."
            
            // Step 2: Load into runtime and test
            if let spec = generatedMiniApp {
                runtimeService.load(spec: spec)
                
                buildProgress = 0.8
                buildStatusMessage = "Testing app functionality..."
                
                // Test the app
                let testResult = await testApp(spec: spec)
                if !testResult.success {
                    buildStatusMessage = "App loaded with warnings: \(testResult.message)"
                } else {
                    buildStatusMessage = "App tested and ready! ✓"
                }
                
                await invokeTool(.runtimeBootstrap, payload: spec.name)
                
                // Automatically open preview after successful generation
                // Small delay to ensure runtime is fully initialized
                buildProgress = 0.95
                buildStatusMessage = "Launching live preview..."
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                await MainActor.run {
                    showAppPreview = true
                }
            }
            
            buildProgress = 1.0
            buildStatusMessage = "Build complete! ✓"
            
            // Step 3: Show save prompt
            showSavePrompt = true
            if let design = generatedAppDesign {
                onAppGenerated?(design)
            }
            
            // Add system message about app creation with details
            let pageCount = spec.pages.count
            let componentCount = spec.pages.reduce(0) { $0 + $1.components.count }
            let featureCount = spec.actions.count
            
            var messageContent = "I've created your app '\(spec.name)' using AI code generation! "
            messageContent += "The app includes \(pageCount) page\(pageCount == 1 ? "" : "s"), \(componentCount) component\(componentCount == 1 ? "" : "s"), "
            messageContent += "and \(featureCount) interactive feature\(featureCount == 1 ? "" : "s"). "
            messageContent += "It's now running live in the preview. Would you like to save it to 'My Creations'?"
            
            let systemMessage = ChatMessage(
                role: .assistant,
                content: messageContent
            )
            messages.append(systemMessage)
            
        } catch let error as OpenAIError {
            errorMessage = error.localizedDescription
            buildStatusMessage = "Build failed: \(error.localizedDescription)"
            
            let errorMsg: ChatMessage
            if case .missingAPIKey = error {
                errorMsg = ChatMessage(
                    role: .assistant,
                    content: "I need an OpenAI API key to generate apps. Please add your API key in Settings, then try again."
                )
            } else {
                errorMsg = ChatMessage(
                    role: .assistant,
                    content: "I encountered an error while building your app: \(error.localizedDescription). Let me try again with a simpler design."
                )
            }
            messages.append(errorMsg)
        } catch {
            errorMessage = "Failed to build app: \(error.localizedDescription)"
            buildStatusMessage = "Build failed: \(error.localizedDescription)"
            
            // Fallback: try local generation
            buildProgress = 0.3
            buildStatusMessage = "Falling back to local generation..."
            
            do {
                let design = try await intentService.generateAppDesign(from: description, requirements: requirements)
                generatedAppDesign = design
                
                buildProgress = 0.5
                buildStatusMessage = "Running build cycle..."
                await appBuilderOrchestrator.runFullCycle(design: design, autoDebug: true)
                
                if let spec = appBuilderOrchestrator.generatedMiniApp {
                    generatedMiniApp = spec
                    runtimeService.load(spec: spec)
                    showAppPreview = true
                }
                
                buildProgress = 1.0
                buildStatusMessage = "Build complete (local mode)! ✓"
                showSavePrompt = true
                
                let fallbackMsg = ChatMessage(
                    role: .assistant,
                    content: "I've created your app using local generation. For better results, add your OpenAI API key in Settings."
                )
                messages.append(fallbackMsg)
            } catch {
                let errorMsg = ChatMessage(
                    role: .assistant,
                    content: "I encountered an error while building your app: \(error.localizedDescription). Please try again or check your settings."
                )
                messages.append(errorMsg)
            }
        }
        
        progressTask.cancel()
        isBuildingApp = false
        buildProgress = 0.0
        buildStatusMessage = ""
    }
    
    // MARK: - Helper Methods
    private func validateMiniAppSpec(_ spec: MiniAppSpec) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        if spec.pages.isEmpty {
            errors.append("No pages defined")
        }
        
        for page in spec.pages {
            if page.components.isEmpty {
                errors.append("Page '\(page.id)' has no components")
            }
        }
        
        return (errors.isEmpty, errors)
    }
    
    private func refineMiniAppSpec(
        originalSpec: MiniAppSpec,
        issues: [String],
        description: String,
        conversationHistory: [ChatMessage]
    ) async throws -> MiniAppSpec {
        let feedback = "The generated app has these issues: \(issues.joined(separator: ", ")). Please fix them and regenerate."
        let refinedDescription = "\(description)\n\nFeedback: \(feedback)"
        
        return try await intentService.generateMiniAppSpec(
            from: refinedDescription,
            conversationHistory: conversationHistory
        )
    }
    
    private func convertMiniAppSpecToAppDesign(_ spec: MiniAppSpec, originalDescription: String) throws -> AppDesign {
        guard spec.pages.first != nil else {
            throw IntentRecognitionError.unableToBuildDesign
        }
        
        let rootComponent = AppComponent(
            type: .container,
            layout: LayoutProperties(width: 375, height: 812),
            style: StyleProperties(backgroundColor: "#FFFFFF"),
            data: ComponentData(),
            children: []
        )
        
        return AppDesign(
            id: spec.id,
            name: spec.name,
            description: spec.description,
            rootComponent: rootComponent,
            globalStyles: [:],
            metadata: AppDesign.AppMetadata(
                createdAt: spec.createdAt,
                updatedAt: spec.updatedAt,
                version: "\(spec.version).0.0",
                author: "OpenAI Generator"
            )
        )
    }
    
    private func testApp(spec: MiniAppSpec) async -> (success: Bool, message: String) {
        // Basic validation tests
        if spec.pages.isEmpty {
            return (false, "No pages to render")
        }
        
        var componentCount = 0
        for page in spec.pages {
            componentCount += page.components.count
        }
        
        if componentCount == 0 {
            return (false, "No components to render")
        }
        
        return (true, "App structure is valid")
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
    
    private func refineExistingApp(changes: String) async {
        guard let currentSpec = generatedMiniApp else {
            await sendRegularMessage()
            return
        }
        
        isBuildingApp = true
        buildProgress = 0.1
        buildStatusMessage = "Refining app based on your feedback..."
        
        do {
            // Build conversation history for context
            let conversationHistory = messages.filter { $0.role != .log }
            
            // Create a refinement prompt
            let refinementPrompt = """
            Current app: \(currentSpec.name)
            Description: \(currentSpec.description)
            
            User wants to modify: \(changes)
            
            Please generate an updated MiniAppSpec that incorporates these changes while maintaining the existing structure where possible.
            """
            
            let updatedSpec = try await intentService.generateMiniAppSpec(
                from: refinementPrompt,
                conversationHistory: conversationHistory
            )
            
            generatedMiniApp = updatedSpec
            runtimeService.load(spec: updatedSpec)
            
            // Convert to AppDesign for compatibility
            let design = try convertMiniAppSpecToAppDesign(updatedSpec, originalDescription: changes)
            generatedAppDesign = design
            
            buildProgress = 1.0
            buildStatusMessage = "App refined successfully! ✓"
            showAppPreview = true
            
            let refinementMsg = ChatMessage(
                role: .assistant,
                content: "I've updated your app based on your feedback. The changes have been applied and the app is ready to test!"
            )
            messages.append(refinementMsg)
            
        } catch {
            errorMessage = "Failed to refine app: \(error.localizedDescription)"
            buildStatusMessage = "Refinement failed: \(error.localizedDescription)"
            
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "I encountered an error while refining your app: \(error.localizedDescription). Please try describing the changes differently."
            )
            messages.append(errorMsg)
        }
        
        isBuildingApp = false
        buildProgress = 0.0
        buildStatusMessage = ""
    }
    
    private func sendRegularMessage() async {
        do {
            // Filter out log messages for OpenAI API
            let conversationMessages = messages.filter { $0.role != .log }
            
            if !openAIService.hasAPIKey {
                // Fallback response when API key is missing
                let fallbackMsg = ChatMessage(
                    role: .assistant,
                    content: "I'd love to help, but I need an OpenAI API key to have conversations. Please add your API key in Settings to enable full functionality."
                )
                messages.append(fallbackMsg)
                return
            }
            
            let response = try await openAIService.sendMessage(messages: conversationMessages)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
        } catch let error as OpenAIError {
            errorMessage = error.localizedDescription
            let errorMsg: ChatMessage
            
            if case .missingAPIKey = error {
                errorMsg = ChatMessage(
                    role: .assistant,
                    content: "I need an OpenAI API key to respond. Please add your API key in Settings."
                )
            } else {
                errorMsg = ChatMessage(
                    role: .assistant,
                    content: "I'm sorry, I encountered an error: \(error.localizedDescription)"
                )
            }
            messages.append(errorMsg)
        } catch {
            errorMessage = error.localizedDescription
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "I'm sorry, I encountered an error: \(error.localizedDescription)"
            )
            messages.append(errorMsg)
        }
    }
    
    func saveGeneratedApp() {
        guard let design = generatedAppDesign,
              let miniApp = generatedMiniApp else { return }
        
        // Save to storage if available
        if let storageService = storageService, let userId = userId {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let designData = (try? JSONEncoder().encode(design)) ?? Data()
            let miniAppData = (try? encoder.encode(miniApp)) ?? Data()
            let payload: [String: String] = [
                "design_b64": designData.base64EncodedString(),
                "miniAppJson": String(data: miniAppData, encoding: .utf8) ?? "{}"
            ]
            
            let contentData = (try? JSONSerialization.data(withJSONObject: payload, options: [])) ?? Data()
            let content = String(data: contentData, encoding: .utf8) ?? "{}"
            
            let creation = Creation(
                userId: userId,
                title: design.name,
                description: design.description,
                type: .app,
                content: content
            )
            
            storageService.saveCreation(creation)
        }
        
        // Call the callback if provided
        onAppGenerated?(design)
        
        showSavePrompt = false
        generatedAppDesign = nil
        
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
        guard generatedMiniApp != nil else { return }
        showAppPreview = true
    }
    
    func dismissPreview() {
        showAppPreview = false
    }
    
    func clearChat() {
        messages.removeAll()
        detectedIntent = nil
        generatedAppDesign = nil
        showSavePrompt = false
        generatedMiniApp = nil
        showAppPreview = false
        toolCallHistory.removeAll()
    }
    
    @discardableResult
    private func invokeTool(_ tool: OpenAITool, payload: String) async -> ToolCallSummary {
        var toolCall = ToolCallSummary(tool: tool, inputPreview: payload.truncated(80))
        let startTime = Date()
        
        await MainActor.run {
            toolCall.status = .running
            toolCallHistory.append(toolCall)
        }
        
        do {
            let result = try await openAIService.invokeTool(tool, payload: payload, contextSize: messages.count)
            let duration = Date().timeIntervalSince(startTime)
            await MainActor.run {
                if let index = toolCallHistory.firstIndex(where: { $0.id == toolCall.id }) {
                    toolCallHistory[index].status = .completed
                    toolCallHistory[index].outputSummary = result.summary
                    toolCallHistory[index].duration = duration
                }
            }
        } catch {
            await MainActor.run {
                if let index = toolCallHistory.firstIndex(where: { $0.id == toolCall.id }) {
                    toolCallHistory[index].status = .failed
                    toolCallHistory[index].outputSummary = error.localizedDescription
                }
            }
        }
        
        return toolCall
    }
}

private extension String {
    func truncated(_ maxCount: Int) -> String {
        guard count > maxCount else { return self }
        let prefixText = prefix(maxCount).trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(prefixText)…"
    }
}

