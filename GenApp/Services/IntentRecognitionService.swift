//
//  IntentRecognitionService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

enum UserIntent {
    case buildApp(description: String, requirements: [String])
    case modifyApp(appId: String?, changes: String)
    case generalChat
    case unknown
}

class IntentRecognitionService {
    private let parser = RequirementParser()
    private let designBuilder = LocalDesignBuilder()
    
    // MARK: - Recognize Intent
    func recognizeIntent(from message: String) async -> UserIntent {
        let lowercased = message.lowercased()
        
        let buildKeywords = ["build", "create", "make", "design", "app", "application", "website", "web app"]
        let hasBuildIntent = buildKeywords.contains { lowercased.contains($0) }
        
        if hasBuildIntent {
            let requirements = await extractRequirements(from: message)
            return .buildApp(description: message, requirements: requirements)
        }
        
        let modifyKeywords = ["modify", "change", "update", "edit", "fix", "improve"]
        if modifyKeywords.contains(where: { lowercased.contains($0) }) {
            return .modifyApp(appId: nil, changes: message)
        }
        
        return .generalChat
    }
    
    // MARK: - Requirement Extraction
    private func extractRequirements(from message: String) async -> [String] {
        await Task.yield()
        return parser.parseRequirements(from: message)
    }
    
    // MARK: - Generate App Design from Description
    func generateAppDesign(from description: String, requirements: [String]) async throws -> AppDesign {
        let sanitized = requirements.isEmpty ? parser.generateFallbackRequirements(from: description) : requirements
        return try designBuilder.buildDesign(description: description, requirements: sanitized)
    }
}

enum IntentRecognitionError: LocalizedError {
    case invalidResponse
    case parsingFailed
    case unableToBuildDesign
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Could not parse app design from response"
        case .parsingFailed:
            return "Failed to parse app design structure"
        case .unableToBuildDesign:
            return "Unable to generate a usable design from the provided prompt"
        }
    }
}

// MARK: - Requirement Parsing
private struct RequirementParser {
    func parseRequirements(from message: String) -> [String] {
        let separators = CharacterSet(charactersIn: ".\n,-")
        let rawPieces = message
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 4 }
        
        let unique = Array(NSOrderedSet(array: rawPieces)) as? [String] ?? rawPieces
        if unique.isEmpty {
            return generateFallbackRequirements(from: message)
        }
        
        return unique
            .prefix(8)
            .map { sanitizeRequirement($0) }
    }
    
    func generateFallbackRequirements(from message: String) -> [String] {
        let lowercased = message.lowercased()
        if lowercased.contains("dashboard") {
            return [
                "Hero header with quick stats",
                "Metrics cards with mini trend lines",
                "Filterable activity list",
                "Primary action button for creating a record"
            ]
        }
        
        if lowercased.contains("chat") {
            return [
                "Conversation list with unread badges",
                "Message composer with send button",
                "Scrollable history with timestamp chips"
            ]
        }
        
        return [
            "Intro section describing the product value",
            "Feature list with icons",
            "Call-to-action button that stays visible",
            "Feedback area with form inputs"
        ]
    }
    
    private func sanitizeRequirement(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Simple UI element" }
        if trimmed.last == ":" {
            return String(trimmed.dropLast())
        }
        return trimmed
    }
}

// MARK: - Local Design Builder
private struct LocalDesignBuilder {
    func buildDesign(description: String, requirements: [String]) throws -> AppDesign {
        guard !requirements.isEmpty else {
            throw IntentRecognitionError.unableToBuildDesign
        }
        
        var children: [AppComponent] = []
        var currentY: Double = 24
        
        // Hero title
        let titleComponent = makeTitleComponent(text: description, yOffset: currentY)
        children.append(titleComponent.component)
        currentY += titleComponent.height + 12
        
        // Generate sections per requirement
        for requirement in requirements {
            let section = makeComponent(for: requirement, yOffset: currentY)
            children.append(section.component)
            currentY += section.height + 12
        }
        
        // CTA at the end
        let cta = makePrimaryButton(yOffset: currentY)
        children.append(cta.component)
        currentY += cta.height + 24
        
        let totalHeight = max(812, currentY)
        let root = AppComponent(
            type: .container,
            layout: LayoutProperties(width: 375, height: totalHeight),
            style: StyleProperties(backgroundColor: "#F5F7FB"),
            data: ComponentData(),
            children: children
        )
        
        return AppDesign(
            name: makeName(from: description),
            description: "Pure front-end build derived from: \(description)",
            rootComponent: root,
            globalStyles: defaultStyles(),
            metadata: AppDesign.AppMetadata(
                createdAt: Date(),
                updatedAt: Date(),
                version: "1.0.0",
                author: "GenApp Local Builder"
            )
        )
    }
    
    private func makeTitleComponent(text: String, yOffset: Double) -> (component: AppComponent, height: Double) {
        let content = text.isEmpty ? "Your custom experience" : text.capitalizedSentence()
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: 72)
        let style = StyleProperties(
            backgroundColor: "#F5F7FB",
            textColor: "#0F172A",
            fontSize: 28,
            fontWeight: "bold",
            fontFamily: "system",
            borderRadius: 0,
            borderWidth: 0,
            borderColor: "#000000",
            opacity: 1.0,
            shadow: nil
        )
        
        var textData = ComponentData()
        textData.text = content
        
        let component = AppComponent(
            type: .text,
            layout: layout,
            style: style,
            data: textData,
            children: []
        )
        
        return (component, layout.height)
    }
    
    private func makeComponent(for requirement: String, yOffset: Double) -> (component: AppComponent, height: Double) {
        let lowercased = requirement.lowercased()
        
        if lowercased.contains("list") || lowercased.contains("feed") || lowercased.contains("activity") {
            return makeListComponent(for: requirement, yOffset: yOffset)
        } else if lowercased.contains("input") || lowercased.contains("form") || lowercased.contains("field") {
            return makeInputComponent(for: requirement, yOffset: yOffset)
        } else if lowercased.contains("button") || lowercased.contains("cta") || lowercased.contains("action") {
            return makeSecondaryButton(for: requirement, yOffset: yOffset)
        } else if lowercased.contains("chart") || lowercased.contains("stat") {
            return makeMetricCard(for: requirement, yOffset: yOffset)
        } else {
            return makeCardComponent(for: requirement, yOffset: yOffset)
        }
    }
    
    private func makeListComponent(for requirement: String, yOffset: Double) -> (component: AppComponent, height: Double) {
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: 200)
        let style = StyleProperties(
            backgroundColor: "#FFFFFF",
            textColor: "#0F172A",
            fontSize: 16,
            fontWeight: "regular",
            fontFamily: "system",
            borderRadius: 24,
            borderWidth: 0,
            borderColor: "#000000",
            opacity: 1.0,
            shadow: StyleProperties.ShadowProperties(color: "#0F172A", radius: 10, offsetX: 0, offsetY: 4)
        )
        
        let items = generateListItems(from: requirement)
        var listData = ComponentData()
        listData.text = requirement.capitalizedSentence()
        listData.items = items
        
        let component = AppComponent(
            type: .list,
            layout: layout,
            style: style,
            data: listData,
            children: []
        )
        
        return (component, layout.height)
    }
    
    private func makeInputComponent(for requirement: String, yOffset: Double) -> (component: AppComponent, height: Double) {
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: 64)
        let style = StyleProperties(
            backgroundColor: "#FFFFFF",
            textColor: "#0F172A",
            fontSize: 16,
            fontWeight: "regular",
            fontFamily: "system",
            borderRadius: 16,
            borderWidth: 1,
            borderColor: "#D1D5DB",
            opacity: 1.0,
            shadow: nil
        )
        
        let placeholder = requirement.cleanPlaceholder()
        var inputData = ComponentData()
        inputData.placeholder = placeholder
        
        let component = AppComponent(
            type: .input,
            layout: layout,
            style: style,
            data: inputData,
            children: []
        )
        
        return (component, layout.height)
    }
    
    private func makeSecondaryButton(for requirement: String, yOffset: Double) -> (component: AppComponent, height: Double) {
        var style = StyleProperties(
            backgroundColor: "#F3F4F6",
            textColor: "#2563EB",
            fontSize: 16,
            fontWeight: "semibold",
            fontFamily: "system",
            borderRadius: 16,
            borderWidth: 1,
            borderColor: "#2563EB",
            opacity: 1.0,
            shadow: nil
        )
        style.backgroundColor = "#E0E7FF"
        
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: 52)
        var buttonData = ComponentData()
        buttonData.text = requirement.capitalizedSentence()
        
        let component = AppComponent(
            type: .button,
            layout: layout,
            style: style,
            data: buttonData,
            children: []
        )
        
        return (component, layout.height)
    }
    
    private func makeMetricCard(for requirement: String, yOffset: Double) -> (component: AppComponent, height: Double) {
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: 120)
        let style = StyleProperties(
            backgroundColor: "#111827",
            textColor: "#F9FAFB",
            fontSize: 18,
            fontWeight: "semibold",
            fontFamily: "system",
            borderRadius: 24,
            borderWidth: 0,
            borderColor: "#000000",
            opacity: 1.0,
            shadow: StyleProperties.ShadowProperties(color: "#0F172A", radius: 16, offsetX: 0, offsetY: 8)
        )
        
        var cardData = ComponentData()
        cardData.text = requirement.capitalizedSentence()
        
        let component = AppComponent(
            type: .card,
            layout: layout,
            style: style,
            data: cardData,
            children: []
        )
        
        return (component, layout.height)
    }
    
    private func makeCardComponent(for requirement: String, yOffset: Double) -> (component: AppComponent, height: Double) {
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: 140)
        let style = StyleProperties(
            backgroundColor: "#FFFFFF",
            textColor: "#111827",
            fontSize: 16,
            fontWeight: "regular",
            fontFamily: "system",
            borderRadius: 24,
            borderWidth: 0,
            borderColor: "#000000",
            opacity: 1.0,
            shadow: StyleProperties.ShadowProperties(color: "#0F172A", radius: 12, offsetX: 0, offsetY: 6)
        )
        
        var infoData = ComponentData()
        infoData.text = requirement.capitalizedSentence()
        
        let component = AppComponent(
            type: .card,
            layout: layout,
            style: style,
            data: infoData,
            children: []
        )
        
        return (component, layout.height)
    }
    
    private func makePrimaryButton(yOffset: Double) -> (component: AppComponent, height: Double) {
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: 56)
        let style = StyleProperties(
            backgroundColor: "#2563EB",
            textColor: "#FFFFFF",
            fontSize: 18,
            fontWeight: "semibold",
            fontFamily: "system",
            borderRadius: 18,
            borderWidth: 0,
            borderColor: "#2563EB",
            opacity: 1.0,
            shadow: StyleProperties.ShadowProperties(color: "#2563EB", radius: 12, offsetX: 0, offsetY: 6)
        )
        
        var ctaData = ComponentData()
        ctaData.text = "Try the prototype"
        
        let component = AppComponent(
            type: .button,
            layout: layout,
            style: style,
            data: ctaData,
            children: []
        )
        
        return (component, layout.height)
    }
    
    private func generateListItems(from requirement: String) -> [String] {
        let tokens = requirement.components(separatedBy: CharacterSet.whitespaces)
        if tokens.count >= 6 {
            let chunked = stride(from: 0, to: min(tokens.count, 12), by: 3).map { index -> String in
                let end = min(index + 3, tokens.count)
                return tokens[index..<end].joined(separator: " ").capitalizedSentence()
            }
            return chunked
        }
        
        return [
            "Sample item one",
            "Sample item two",
            "Sample item three"
        ]
    }
    
    private func makeName(from description: String) -> String {
        let words = description
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(3)
            .map { $0.capitalized }
        
        let base = words.joined(separator: " ")
        return base.isEmpty ? "Generated App" : "\(base) Prototype"
    }
    
    private func defaultStyles() -> [String: StyleProperties] {
        var button = StyleProperties(
            backgroundColor: "#2563EB",
            textColor: "#FFFFFF",
            fontSize: 18,
            fontWeight: "semibold",
            fontFamily: "system",
            borderRadius: 18,
            borderWidth: 0,
            borderColor: "#2563EB",
            opacity: 1.0,
            shadow: StyleProperties.ShadowProperties(color: "#93C5FD", radius: 16, offsetX: 0, offsetY: 6)
        )
        
        var text = StyleProperties(
            backgroundColor: "#F5F7FB",
            textColor: "#0F172A",
            fontSize: 16,
            fontWeight: "regular",
            fontFamily: "system",
            borderRadius: 0,
            borderWidth: 0,
            borderColor: "#000000",
            opacity: 1.0,
            shadow: nil
        )
        
        return [
            "primaryButton": button,
            "bodyText": text
        ]
    }
}

private extension String {
    func capitalizedSentence() -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Untitled" }
        return trimmed.prefix(1).capitalized + trimmed.dropFirst()
    }
    
    func cleanPlaceholder() -> String {
        let lower = self.lowercased()
        if lower.contains("email") {
            return "Email address"
        } else if lower.contains("name") {
            return "Full name"
        } else if lower.contains("search") {
            return "Search…"
        }
        return "Enter details"
    }
}

extension UserIntent {
    var summary: String {
        switch self {
        case .buildApp(_, let requirements):
            return "buildApp (\(requirements.count) requirements)"
        case .modifyApp(let appId, _):
            return "modifyApp (appId: \(appId ?? "n/a"))"
        case .generalChat:
            return "generalChat"
        case .unknown:
            return "unknown"
        }
    }
}

