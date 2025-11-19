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
    private let knowledgeBase = RequirementKnowledgeBase()
    private let expander = RequirementExpander()
    
    func parseRequirements(from message: String) -> [String] {
        // 1. Try curated templates first (ensures we don't mirror the input text)
        if let templateRequirements = knowledgeBase.matchRequirements(for: message),
           !templateRequirements.isEmpty {
            return templateRequirements
        }
        
        // 2. Fall back to heuristic parsing
        let separators = CharacterSet(charactersIn: ".\n,-")
        let rawPieces = message
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 4 }
        
        var unique = Array(NSOrderedSet(array: rawPieces)) as? [String] ?? rawPieces
        
        // Remove entries that essentially repeat the whole message (prevents "Build me..." echo)
        unique.removeAll {
            $0.caseInsensitiveCompare(message.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
        }
        
        guard !unique.isEmpty else {
            return generateFallbackRequirements(from: message)
        }
        
        let sanitized = unique
            .prefix(8)
            .map { sanitizeRequirement($0) }
        
        let enriched = expander.expand(requirements: Array(sanitized), context: message)
        return enriched.isEmpty ? generateFallbackRequirements(from: message) : enriched
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
    private let titleGenerator = TitleGenerator()
    private let knowledgeBase = RequirementKnowledgeBase()
    
    func buildDesign(description: String, requirements: [String]) throws -> AppDesign {
        if let template = knowledgeBase.template(for: description) {
            return buildTemplateDesign(template: template, userDescription: description)
        }
        guard !requirements.isEmpty else {
            throw IntentRecognitionError.unableToBuildDesign
        }
        return buildGenericDesign(description: description, requirements: requirements)
    }
    
    // MARK: - Template-driven designs
    private func buildTemplateDesign(template: RequirementKnowledgeBase.Template, userDescription: String) -> AppDesign {
        let components = templateComponents(for: template)
        let totalHeight = max(812, contentHeight(for: components) + 32)
        let root = AppComponent(
            type: .container,
            layout: LayoutProperties(width: 375, height: totalHeight),
            style: StyleProperties(backgroundColor: template.palette.background),
            data: ComponentData(),
            children: components
        )
        
        return AppDesign(
            name: template.title,
            description: "Generated \(template.title.lowercased()) experience for: \(userDescription)",
            rootComponent: root,
            globalStyles: defaultStyles(primary: template.palette.primary),
            metadata: AppDesign.AppMetadata(
                createdAt: Date(),
                updatedAt: Date(),
                version: "1.0.0",
                author: "GenApp Template: \(template.title)"
            )
        )
    }
    
    private func templateComponents(for template: RequirementKnowledgeBase.Template) -> [AppComponent] {
        switch template.type {
        case .clock:
            return clockComponents(palette: template.palette)
        case .weather:
            return weatherComponents(palette: template.palette)
        case .todo:
            return todoComponents(palette: template.palette)
        case .finance:
            return financeComponents(palette: template.palette)
        case .fitness:
            return fitnessComponents(palette: template.palette)
        case .recipe:
            return recipeComponents(palette: template.palette)
        }
    }
    
    // MARK: - Generic builder (fallback)
    private func buildGenericDesign(description: String, requirements: [String]) -> AppDesign {
        var children: [AppComponent] = []
        var currentY: Double = 24
        
        let heroTitle = titleGenerator.makeTitle(from: description)
        let titleComponent = makeTitleComponent(text: heroTitle, yOffset: currentY)
        children.append(titleComponent.component)
        currentY += titleComponent.height + 12
        
        for requirement in requirements {
            let section = makeComponent(for: requirement, yOffset: currentY)
            children.append(section.component)
            currentY += section.height + 12
        }
        
        let ctaText = knowledgeBase.ctaCopy(for: description) ?? "Try the prototype"
        let cta = makePrimaryButton(text: ctaText, yOffset: currentY)
        children.append(cta.component)
        currentY += cta.height + 24
        
        let totalHeight = max(812, currentY)
        let palette = knowledgeBase.palette(for: description)
        
        let root = AppComponent(
            type: .container,
            layout: LayoutProperties(width: 375, height: totalHeight),
            style: StyleProperties(backgroundColor: palette.background),
            data: ComponentData(),
            children: children
        )
        
        return AppDesign(
            name: makeName(from: description),
            description: "Pure front-end build derived from: \(description)",
            rootComponent: root,
            globalStyles: defaultStyles(primary: palette.primary),
            metadata: AppDesign.AppMetadata(
                createdAt: Date(),
                updatedAt: Date(),
                version: "1.0.0",
                author: "GenApp Local Builder"
            )
        )
    }
    
    // MARK: - Template component sets
    private func clockComponents(palette: RequirementKnowledgeBase.DesignPalette) -> [AppComponent] {
        var components: [AppComponent] = []
        var y: Double = 32
        
        components.append(textComponent("Clock Control Center", yOffset: y, height: 48, fontSize: 30, fontWeight: "bold", textColor: "#0F172A", backgroundColor: palette.background))
        y += 60
        components.append(textComponent("San Francisco, CA", yOffset: y, height: 32, fontSize: 18, fontWeight: "semibold", textColor: "#475569", backgroundColor: palette.background))
        y += 44
        components.append(textComponent("Monday, Jul 8 • 10:24 AM", yOffset: y, height: 40, fontSize: 24, fontWeight: "semibold", textColor: "#0F172A", backgroundColor: palette.background))
        y += 52
        
        components.append(listComponent(items: [
            "New York — 1:24 PM",
            "London — 6:24 PM",
            "Tokyo — 2:24 AM"
        ], yOffset: y, height: 168, backgroundColor: "#FFFFFF"))
        y += 180
        
        components.append(listComponent(items: [
            "06:30 • Wake up alarm",
            "12:00 • Lunch reminder",
            "18:00 • Wind-down alarm"
        ], yOffset: y, height: 168, backgroundColor: "#FFFFFF"))
        y += 180
        
        components.append(buttonComponent(text: "Add new alarm", yOffset: y, backgroundColor: palette.primary, textColor: "#FFFFFF"))
        
        return components
    }
    
    private func weatherComponents(palette: RequirementKnowledgeBase.DesignPalette) -> [AppComponent] {
        var components: [AppComponent] = []
        var y: Double = 32
        
        components.append(textComponent("Weather Snapshot", yOffset: y, height: 48, fontSize: 28, fontWeight: "bold", textColor: "#0F172A", backgroundColor: palette.background))
        y += 60
        components.append(textComponent("Seattle, WA", yOffset: y, height: 32, fontSize: 18, fontWeight: "semibold", textColor: "#0369A1", backgroundColor: palette.background))
        y += 44
        components.append(textComponent("72° • Sunny", yOffset: y, height: 60, fontSize: 42, fontWeight: "bold", textColor: "#0F172A", backgroundColor: palette.background))
        y += 72
        components.append(textComponent("Feels like 74° • Humidity 52% • Wind 6 mph", yOffset: y, height: 36, fontSize: 16, fontWeight: "regular", textColor: "#0F172A", backgroundColor: palette.background))
        y += 48
        
        components.append(listComponent(items: [
            "1 PM — 72°",
            "3 PM — 74°",
            "5 PM — 69°",
            "7 PM — 65°"
        ], yOffset: y, height: 196, backgroundColor: "#FFFFFF"))
        y += 208
        
        components.append(listComponent(items: [
            "UV Index — Moderate",
            "Humidity — 52%",
            "Visibility — 9 miles"
        ], yOffset: y, height: 150, backgroundColor: "#FFFFFF"))
        y += 162
        
        components.append(buttonComponent(text: "Enable alerts", yOffset: y, backgroundColor: palette.primary, textColor: "#FFFFFF"))
        
        return components
    }
    
    private func todoComponents(palette: RequirementKnowledgeBase.DesignPalette) -> [AppComponent] {
        var components: [AppComponent] = []
        var y: Double = 32
        
        components.append(textComponent("Focus Taskboard", yOffset: y, height: 48, fontSize: 28, fontWeight: "bold", textColor: "#111827", backgroundColor: palette.background))
        y += 60
        components.append(textComponent("3 tasks left • 1 due today", yOffset: y, height: 32, fontSize: 18, fontWeight: "semibold", textColor: "#4C1D95", backgroundColor: palette.background))
        y += 44
        
        components.append(inputComponent(placeholder: "Add a new task...", yOffset: y))
        y += 76
        
        components.append(listComponent(items: [
            "Design review with product",
            "Update onboarding checklist",
            "Plan sprint retro agenda"
        ], yOffset: y, height: 168, backgroundColor: "#FFFFFF"))
        y += 180
        
        components.append(listComponent(items: [
            "Progress — 65%",
            "Focus streak — 4 days",
            "Next break — 25 min"
        ], yOffset: y, height: 150, backgroundColor: "#FFFFFF"))
        y += 162
        
        components.append(buttonComponent(text: "Start focus session", yOffset: y, backgroundColor: palette.primary, textColor: "#FFFFFF"))
        
        return components
    }
    
    private func financeComponents(palette: RequirementKnowledgeBase.DesignPalette) -> [AppComponent] {
        var components: [AppComponent] = []
        var y: Double = 32
        
        components.append(textComponent("Money Dashboard", yOffset: y, height: 48, fontSize: 28, fontWeight: "bold", textColor: "#064E3B", backgroundColor: palette.background))
        y += 60
        components.append(textComponent("Balance • $24,830", yOffset: y, height: 36, fontSize: 20, fontWeight: "semibold", textColor: "#14532D", backgroundColor: palette.background))
        y += 48
        components.append(textComponent("Income $8,200 • Expenses $3,420 • +12% vs last month", yOffset: y, height: 40, fontSize: 16, fontWeight: "regular", textColor: "#14532D", backgroundColor: palette.background))
        y += 52
        
        components.append(listComponent(items: [
            "Design contract • +$2,400",
            "Cloud provider • -$640",
            "Advertising • -$320",
            "Subscription revenue • +$980"
        ], yOffset: y, height: 212, backgroundColor: "#FFFFFF"))
        y += 224
        
        components.append(listComponent(items: [
            "Filters — Month, Quarter, Year",
            "Forecast — On track",
            "Next invoice — Due Fri"
        ], yOffset: y, height: 150, backgroundColor: "#FFFFFF"))
        y += 162
        
        components.append(buttonComponent(text: "Create invoice", yOffset: y, backgroundColor: palette.primary, textColor: "#FFFFFF"))
        
        return components
    }
    
    private func fitnessComponents(palette: RequirementKnowledgeBase.DesignPalette) -> [AppComponent] {
        var components: [AppComponent] = []
        var y: Double = 32
        
        components.append(textComponent("Fitness Companion", yOffset: y, height: 48, fontSize: 28, fontWeight: "bold", textColor: "#9A3412", backgroundColor: palette.background))
        y += 60
        components.append(textComponent("Calories 540 • Steps 8,120 • Move ring 78%", yOffset: y, height: 40, fontSize: 18, fontWeight: "semibold", textColor: "#7C2D12", backgroundColor: palette.background))
        y += 52
        
        components.append(listComponent(items: [
            "HIIT — 28 min • 320 kcal",
            "Yoga flow — 18 min • 120 kcal",
            "Outdoor walk — 35 min • 210 kcal"
        ], yOffset: y, height: 180, backgroundColor: "#FFFFFF"))
        y += 192
        
        components.append(listComponent(items: [
            "Weekly goal — 5 workouts",
            "Hydration — 48 oz / 80 oz",
            "Recovery — Good"
        ], yOffset: y, height: 168, backgroundColor: "#FFFFFF"))
        y += 180
        
        components.append(buttonComponent(text: "Start workout", yOffset: y, backgroundColor: palette.primary, textColor: "#FFFFFF"))
        
        return components
    }
    
    private func recipeComponents(palette: RequirementKnowledgeBase.DesignPalette) -> [AppComponent] {
        var components: [AppComponent] = []
        var y: Double = 32
        
        components.append(textComponent("Chef Companion", yOffset: y, height: 48, fontSize: 28, fontWeight: "bold", textColor: "#9A3412", backgroundColor: palette.background))
        y += 60
        components.append(textComponent("Mediterranean Grain Bowl • 35 min", yOffset: y, height: 40, fontSize: 18, fontWeight: "semibold", textColor: "#7C2D12", backgroundColor: palette.background))
        y += 52
        components.append(textComponent("Serves 2 • 640 kcal • Prep 15 • Cook 20", yOffset: y, height: 36, fontSize: 16, fontWeight: "regular", textColor: "#7C2D12", backgroundColor: palette.background))
        y += 48
        
        components.append(listComponent(items: [
            "1 cup quinoa",
            "Roasted chickpeas",
            "Cucumber ribbons",
            "Herbed yogurt dressing"
        ], yOffset: y, height: 196, backgroundColor: "#FFFFFF"))
        y += 208
        
        components.append(listComponent(items: [
            "Cook quinoa until fluffy",
            "Roast chickpeas with paprika",
            "Layer greens, grains, veggies",
            "Finish with dressing + mint"
        ], yOffset: y, height: 196, backgroundColor: "#FFFFFF"))
        y += 208
        
        components.append(buttonComponent(text: "Save to favorites", yOffset: y, backgroundColor: palette.primary, textColor: "#FFFFFF"))
        
        return components
    }
    
    // MARK: - Generic component builders (existing logic)
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
    
    private func makePrimaryButton(text: String, yOffset: Double) -> (component: AppComponent, height: Double) {
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
        ctaData.text = text.capitalizedSentence()
        
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
    
    private func defaultStyles(primary: String) -> [String: StyleProperties] {
        var button = StyleProperties(
            backgroundColor: primary,
            textColor: "#FFFFFF",
            fontSize: 18,
            fontWeight: "semibold",
            fontFamily: "system",
            borderRadius: 18,
            borderWidth: 0,
            borderColor: primary,
            opacity: 1.0,
            shadow: StyleProperties.ShadowProperties(color: primary, radius: 16, offsetX: 0, offsetY: 6)
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
    
    // MARK: - Template helper builders
    private func textComponent(_ text: String, yOffset: Double, height: Double, fontSize: Double, fontWeight: String, textColor: String, backgroundColor: String) -> AppComponent {
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: height)
        var style = StyleProperties(
            backgroundColor: backgroundColor,
            textColor: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: "system",
            borderRadius: 0,
            borderWidth: 0,
            borderColor: "#000000",
            opacity: 1.0,
            shadow: nil
        )
        var data = ComponentData()
        data.text = text
        return AppComponent(type: .text, layout: layout, style: style, data: data, children: [])
    }
    
    private func listComponent(items: [String], yOffset: Double, height: Double, backgroundColor: String) -> AppComponent {
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: height)
        var style = StyleProperties(
            backgroundColor: backgroundColor,
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
        var data = ComponentData()
        data.items = items
        return AppComponent(type: .list, layout: layout, style: style, data: data, children: [])
    }
    
    private func buttonComponent(text: String, yOffset: Double, backgroundColor: String, textColor: String) -> AppComponent {
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: 56)
        let style = StyleProperties(
            backgroundColor: backgroundColor,
            textColor: textColor,
            fontSize: 18,
            fontWeight: "semibold",
            fontFamily: "system",
            borderRadius: 18,
            borderWidth: 0,
            borderColor: backgroundColor,
            opacity: 1.0,
            shadow: StyleProperties.ShadowProperties(color: backgroundColor, radius: 12, offsetX: 0, offsetY: 6)
        )
        var data = ComponentData()
        data.text = text
        return AppComponent(type: .button, layout: layout, style: style, data: data, children: [])
    }
    
    private func inputComponent(placeholder: String, yOffset: Double) -> AppComponent {
        let layout = LayoutProperties(x: 16, y: yOffset, width: 343, height: 64)
        var style = StyleProperties(
            backgroundColor: "#FFFFFF",
            textColor: "#0F172A",
            fontSize: 16,
            fontWeight: "regular",
            fontFamily: "system",
            borderRadius: 16,
            borderWidth: 1,
            borderColor: "#CBD5F5",
            opacity: 1.0,
            shadow: nil
        )
        var data = ComponentData()
        data.placeholder = placeholder
        return AppComponent(type: .input, layout: layout, style: style, data: data, children: [])
    }
    
    private func contentHeight(for components: [AppComponent]) -> Double {
        components.map { $0.layout.y + $0.layout.height }.max() ?? 812
    }
}

// MARK: - Domain Knowledge Helpers
private struct RequirementKnowledgeBase {
    struct Template {
        let id: String
        let keywords: [String]
        let title: String
        let requirements: [String]
        let palette: DesignPalette
        let cta: String
        let type: TemplateType
    }
    
    struct DesignPalette {
        let background: String
        let primary: String
    }
    
    enum TemplateType {
        case clock
        case weather
        case todo
        case finance
        case fitness
        case recipe
    }
    
    private let templates: [Template] = [
        Template(
            id: "clock",
            keywords: ["clock", "time", "timer", "alarm"],
            title: "Clock Control Center",
            requirements: [
                "Hero clock showing current hour, minute, and seconds in large type",
                "Secondary card that displays today's date, weekday, and timezone",
                "Row of quick actions for Start Timer, New Alarm, and Focus Session",
                "List of saved world clocks with city labels and time deltas",
                "CTA card for creating a new alarm with repeat options"
            ],
            palette: DesignPalette(background: "#EEF3FF", primary: "#2563EB"),
            cta: "Add new alarm",
            type: .clock
        ),
        Template(
            id: "weather",
            keywords: ["weather", "forecast", "temperature", "climate"],
            title: "Weather Snapshot",
            requirements: [
                "Hero section with current temperature, condition icon, and location",
                "Hourly forecast row showing next 6 hours with mini charts",
                "Detailed metrics card covering humidity, wind, and UV index",
                "Weekly forecast list with day labels and hi/lo temperatures",
                "Prompt to enable severe weather alerts"
            ],
            palette: DesignPalette(background: "#F2FAFF", primary: "#0EA5E9"),
            cta: "Enable alerts",
            type: .weather
        ),
        Template(
            id: "todo",
            keywords: ["todo", "task", "productivity", "list", "planner"],
            title: "Focus Taskboard",
            requirements: [
                "Summary card showing tasks left, completed, and streak",
                "Input field to capture a new task with due date picker",
                "Priority list segmented by Today, Upcoming, and Someday",
                "Progress tracker bar with percentage complete",
                "CTA button to start focus timer for the top task"
            ],
            palette: DesignPalette(background: "#F8F9FB", primary: "#7C3AED"),
            cta: "Start focus session",
            type: .todo
        ),
        Template(
            id: "finance",
            keywords: ["finance", "budget", "expense", "money", "invoice"],
            title: "Money Dashboard",
            requirements: [
                "Balance overview card with income vs expenses delta",
                "Chart card visualizing spending by category",
                "List of latest transactions with amount badges",
                "Filter chips for Month, Quarter, Year",
                "CTA to create a new invoice"
            ],
            palette: DesignPalette(background: "#F5FBF7", primary: "#16A34A"),
            cta: "Create invoice",
            type: .finance
        ),
        Template(
            id: "fitness",
            keywords: ["fitness", "workout", "health", "steps", "run", "exercise"],
            title: "Fitness Companion",
            requirements: [
                "Hero stats card with calories, steps, and move ring",
                "Workout history list highlighting most recent sessions",
                "Goals card with editable targets for the week",
                "Hydration tracker with water intake chips",
                "CTA button to start a new workout"
            ],
            palette: DesignPalette(background: "#FDF7F3", primary: "#FB923C"),
            cta: "Start workout",
            type: .fitness
        ),
        Template(
            id: "recipe",
            keywords: ["recipe", "cooking", "meal", "kitchen", "food"],
            title: "Chef Companion",
            requirements: [
                "Hero recipe card with dish photo and cook time",
                "Ingredient checklist with toggles",
                "Step-by-step instructions list with timers",
                "Nutrition facts panel",
                "CTA to save recipe to favorites"
            ],
            palette: DesignPalette(background: "#FFF8F0", primary: "#EA580C"),
            cta: "Save to favorites",
            type: .recipe
        )
    ]
    
    func template(for message: String) -> Template? {
        let lower = message.lowercased()
        let scored = templates.compactMap { template -> (Template, Int)? in
            let score = template.keywords.reduce(into: 0) { partial, keyword in
                if lower.contains(keyword) {
                    partial += 1
                }
            }
            return score > 0 ? (template, score) : nil
        }
        return scored.sorted { $0.1 > $1.1 }.first?.0
    }
    
    func matchRequirements(for message: String) -> [String]? {
        template(for: message)?.requirements
    }
    
    func suggestedTitle(for message: String) -> String? {
        template(for: message)?.title
    }
    
    func ctaCopy(for message: String) -> String? {
        template(for: message)?.cta
    }
    
    func palette(for message: String) -> DesignPalette {
        template(for: message)?.palette ?? DesignPalette(background: "#F5F7FB", primary: "#2563EB")
    }
}

private struct RequirementExpander {
    func expand(requirements: [String], context: String) -> [String] {
        var enriched: [String] = []
        for requirement in requirements {
            let lower = requirement.lowercased()
            if lower.contains("clock") || lower.contains("time") {
                enriched.append(contentsOf: [
                    "Large digital clock showing the current time clearly",
                    "Analog clock visualization with ticking seconds ring",
                    "Timezone selector to switch between saved cities"
                ])
                continue
            }
            
            if lower.contains("alarm") || lower.contains("reminder") {
                enriched.append(contentsOf: [
                    "Alarm editor with fields for title, time, and repeat",
                    "List of active alarms with toggle switches"
                ])
                continue
            }
            
            if lower.contains("list") || lower.contains("feed") {
                enriched.append("Scrollable card list titled \(requirement.capitalizedSentence()) with avatars and metadata")
                continue
            }
            
            enriched.append(requirement.capitalizedSentence())
        }
        
        if enriched.isEmpty {
            return []
        }
        
        // Ensure uniqueness while preserving order
        var seen = Set<String>()
        let unique = enriched.filter { seen.insert($0.lowercased()).inserted }
        return Array(unique.prefix(8))
    }
}

private struct TitleGenerator {
    private let knowledgeBase = RequirementKnowledgeBase()
    
    func makeTitle(from description: String) -> String {
        if let preset = knowledgeBase.suggestedTitle(for: description) {
            return preset
        }
        
        let cleaned = description
            .replacingOccurrences(of: #"(?i)build (me|us|a|an)\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)please\s+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleaned.isEmpty else { return "Custom Prototype" }
        
        let firstSentence = cleaned
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .first ?? cleaned
        
        return firstSentence.capitalizedSentence()
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

