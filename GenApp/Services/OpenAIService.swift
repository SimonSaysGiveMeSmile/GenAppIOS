//
//  OpenAIService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

/// Real OpenAI API integration for generating app code and multi-turn conversations
class OpenAIService {
    private let apiKey: String?
    private let baseURL = "https://api.openai.com/v1"
    
    init() {
        self.apiKey = UserDefaults.standard.string(forKey: "openai_api_key")
    }
    
    var hasAPIKey: Bool {
        apiKey != nil && !apiKey!.isEmpty
    }
    
    // MARK: - Chat Completion
    func sendMessage(messages: [ChatMessage]) async throws -> String {
        guard hasAPIKey, let apiKey = apiKey else {
            throw OpenAIError.missingAPIKey
        }
        
        guard !messages.isEmpty else {
            throw OpenAIError.emptyPrompt
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages.map { msg in
                [
                    "role": msg.role.rawValue,
                    "content": msg.content
                ]
            },
            "temperature": 0.7,
            "max_tokens": 2000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        return content
    }
    
    // MARK: - Generate MiniAppSpec
    func generateMiniAppSpec(from description: String, conversationHistory: [ChatMessage] = []) async throws -> MiniAppSpec {
        guard hasAPIKey, let apiKey = apiKey else {
            throw OpenAIError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build system prompt for MiniAppSpec generation
        let systemPrompt = """
You are an expert app generator that creates comprehensive, fully-functional MiniApp specifications in JSON format.

CRITICAL INSTRUCTIONS:
1. DO NOT simply repeat or echo the user's description. Instead, interpret their intent and create a complete, polished app experience.
2. ADD CREATIVE FEATURES beyond what the user explicitly mentioned. For example:
   - If they ask for a "habit tracker", include: streak counters, progress charts, reminder settings, achievement badges, statistics dashboard
   - If they ask for a "todo app", include: priority levels, categories/tags, due dates, completion animations, search/filter
   - If they ask for a "weather app", include: hourly forecasts, weekly outlook, location search, weather alerts, detailed metrics
3. CREATE MULTIPLE PAGES when appropriate (e.g., main screen, settings, detail views, statistics)
4. ADD INTERACTIVE ELEMENTS: buttons, toggles, inputs, lists with meaningful actions
5. USE REALISTIC DATA: populate lists with example items, use appropriate placeholders, add sample content
6. DESIGN COMPLETE USER FLOWS: ensure users can navigate between pages and perform meaningful actions

Generate a complete MiniAppSpec JSON object based on the user's description. The MiniAppSpec should include:
- id: unique identifier (UUID format)
- ownerId: "user"
- name: creative, descriptive app name (not just "Habit Tracker" but something like "HabitHero" or "Daily Streaks")
- description: detailed description explaining what the app does and its key features
- category: one of utility, learning, productivity, wellness, entertainment, finance
- version: 1
- pages: array of pages (minimum 1, ideally 2-3 for complex apps). Each page MUST include:
  * id: unique page identifier
  * name: page name (optional)
  * layout: one of "scroll", "center", or "grid" (REQUIRED - default to "scroll" if unsure)
  * components: array of components
- capabilities: array of relevant capabilities (timer, flashlight, localNotifications, haptics)
- initialState: object with initial state values (include realistic default data)
- actions: array of actions (NAVIGATE, SHOW_ALERT, SET_STATE, TOGGLE_FLASHLIGHT, START_TIMER) - create meaningful actions that connect components
- createdAt: current timestamp (ISO 8601 format)
- updatedAt: current timestamp (ISO 8601 format)

Component types: container, label, button, toggle, image, timerDisplay, list, input, quizQuestion, spacer

COMPONENT GUIDELINES:
- Use containers to group related components
- Add labels with descriptive text (not just "Label")
- Create buttons with clear action labels
- Use lists with 3-5 realistic example items
- Add inputs with helpful placeholders
- Use appropriate styling (colors, spacing, padding)
- Connect buttons to actions using actionIds

EXAMPLE STRUCTURE for a habit tracker:
- Page 1 (Main): Title, streak counter, today's habits list, add habit button
- Page 2 (Add Habit): Form with input fields, save button
- Page 3 (Stats): Progress charts, achievement list

Return ONLY valid JSON, no markdown code blocks, no explanations. The JSON must be parseable and complete.
"""
        
        var messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        // Add conversation history
        for msg in conversationHistory {
            messages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }
        
        // Add current request
        messages.append([
            "role": "user",
            "content": "Generate a MiniAppSpec JSON for: \(description)"
        ])
        
        var requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.3, // Lower temperature for more consistent JSON
            "max_tokens": 4000
        ]
        
        // Add response format for JSON mode (only for gpt-4o and newer models)
        requestBody["response_format"] = ["type": "json_object"]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        // Parse the JSON content
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Try to extract JSON from markdown code blocks if present
        var cleanedContent = content
            .replacingOccurrences(of: "```json\n", with: "")
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```\n", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to find JSON object in the response if it's wrapped in text
        if !cleanedContent.hasPrefix("{") {
            // Try to extract JSON object using regex
            if let jsonRange = cleanedContent.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression) {
                cleanedContent = String(cleanedContent[jsonRange])
            }
        }
        
        guard let cleanedData = cleanedContent.data(using: .utf8) else {
            throw OpenAIError.parsingFailed
        }
        
        do {
            let spec = try decoder.decode(MiniAppSpec.self, from: cleanedData)
            
            // Validate and fix common issues
            let validatedSpec = validateAndFixSpec(spec)
            
            return validatedSpec
        } catch let decodingError as DecodingError {
            print("JSON parsing error: \(decodingError)")
            if case .keyNotFound(let key, let context) = decodingError {
                print("Missing key: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            }
            print("Content preview: \(cleanedContent.prefix(1000))")
            throw OpenAIError.parsingFailed
        } catch {
            print("JSON parsing error: \(error)")
            print("Content preview: \(cleanedContent.prefix(1000))")
            throw OpenAIError.parsingFailed
        }
    }
    
    // MARK: - Tool Invocation (for backward compatibility)
    func invokeTool(_ tool: OpenAITool, payload: String, contextSize: Int) async throws -> ToolInvocationResult {
        // For now, return a simple result
        // In the future, this could call specific OpenAI functions
        return ToolInvocationResult(
            summary: "Processed \(tool.displayName) with payload",
            suggestedNextStep: "continue"
        )
    }
    
    // MARK: - Helper Methods
    private func validateAndFixSpec(_ spec: MiniAppSpec) -> MiniAppSpec {
        // Ensure at least one page exists
        var pages = spec.pages
        if pages.isEmpty {
            // Create a default page
            pages = [
                MiniAppPage(
                    id: "main",
                    title: spec.name,
                    layout: .scroll,
                    components: []
                )
            ]
        }
        
        // Ensure all pages have at least basic structure and all components have IDs
        pages = pages.map { page in
            var components = page.components
            if components.isEmpty {
                // Add a default label component
                components = [
                    MiniAppComponent(
                        id: UUID().uuidString,
                        type: .label,
                        props: MiniAppComponentProps(
                            text: "Welcome to \(spec.name)",
                            style: .defaultStyle
                        ),
                        bindings: nil,
                        actionIds: [],
                        children: []
                    )
                ]
            }
            
            return MiniAppPage(
                id: page.id,
                title: page.title,
                layout: page.layout,
                components: components
            )
        }
        
        // Create a new spec with validated pages
        return MiniAppSpec(
            id: spec.id,
            ownerId: spec.ownerId,
            name: spec.name,
            description: spec.description,
            category: spec.category,
            version: spec.version,
            pages: pages,
            capabilities: spec.capabilities,
            initialState: spec.initialState,
            actions: spec.actions,
            createdAt: spec.createdAt,
            updatedAt: Date()
        )
    }
}

enum OpenAIError: LocalizedError {
    case emptyPrompt
    case missingAPIKey
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case parsingFailed
    case unsupportedRequest
    
    var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "I need a user prompt to respond to."
        case .missingAPIKey:
            return "OpenAI API key is not configured. Please add your API key in Settings."
        case .invalidResponse:
            return "Received an invalid response from OpenAI API."
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "OpenAI API error: \(message)"
        case .parsingFailed:
            return "Failed to parse the generated app specification."
        case .unsupportedRequest:
            return "That request is not supported."
        }
    }
}

