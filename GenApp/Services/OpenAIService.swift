//
//  OpenAIService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

/// A lightweight, fully local response generator that mimics an AI assistant
/// without performing any network calls. It keeps the experience async-friendly
/// while ensuring the entire app remains front-end only.
class OpenAIService {
    private let responseGenerator = LocalResponseGenerator()
    
    func sendMessage(messages: [ChatMessage]) async throws -> String {
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else {
            throw OpenAIError.emptyPrompt
        }
        
        // Simulate thinking time to keep the UI flow familiar.
        try await Task.sleep(nanoseconds: 250_000_000)
        return responseGenerator.generateResponse(
            for: lastUserMessage.content,
            contextCount: messages.count
        )
    }
}

enum OpenAIError: LocalizedError {
    case emptyPrompt
    case unsupportedRequest
    
    var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "I need a user prompt to respond to."
        case .unsupportedRequest:
            return "That request is not supported in the lightweight front-end mode."
        }
    }
}

// MARK: - Local Response Generation
private struct LocalResponseGenerator {
    private let layoutIdeas = [
        "a glassmorphic hero with stacked cards",
        "a split view layout with a sticky action rail",
        "a minimalist single-column scroll with floating CTAs",
        "modular sections that feel like draggable widgets",
        "tabbed content panels with inline previews"
    ]
    
    private let paletteIdeas = [
        "indigo & lavender gradients",
        "emerald with muted neutrals",
        "sunset orange highlights on slate",
        "midnight blues with cyan accents",
        "soft gray surfaces with electric pink touches"
    ]
    
    func generateResponse(for prompt: String, contextCount: Int) -> String {
        let summary = summarize(prompt)
        let layout = layoutIdeas.randomElement() ?? layoutIdeas[0]
        let palette = paletteIdeas.randomElement() ?? paletteIdeas[1]
        let interactions = highlightInteractions(in: prompt)
        
        return """
Here’s a purely front-end concept for \(summary):

- Layout: \(layout.capitalized)
- Visual system: \(palette)
- Interactions: \(interactions)
- Data: mocked in-memory models only (no APIs or pipelines)

I’ll stitch together ready-to-preview HTML/CSS/JS plus SwiftUI stubs, then surface the build logs above so you can see exactly what the local “backend” is doing.
"""
    }
    
    private func summarize(_ prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "your idea" }
        
        let separators = CharacterSet(charactersIn: ".!?")
        if let firstSentence = trimmed.components(separatedBy: separators).first,
           firstSentence.count > 5 {
            return firstSentence.lowercased().hasSuffix("app") ? firstSentence : firstSentence + " app"
        }
        
        return trimmed
    }
    
    private func highlightInteractions(in prompt: String) -> String {
        let lowercased = prompt.lowercased()
        var interactions: [String] = []
        
        if lowercased.contains("form") || lowercased.contains("input") {
            interactions.append("inline forms with optimistic validation")
        }
        if lowercased.contains("chart") || lowercased.contains("stats") {
            interactions.append("animated charts rendered on the main thread")
        }
        if lowercased.contains("chat") || lowercased.contains("message") {
            interactions.append("chat bubbles powered by local state")
        }
        if lowercased.contains("list") || lowercased.contains("feed") {
            interactions.append("virtualized lists backed by mock data")
        }
        
        if interactions.isEmpty {
            interactions.append("tap + drag gestures handled entirely in the UI layer")
        }
        
        return interactions.joined(separator: ", ")
    }
}

