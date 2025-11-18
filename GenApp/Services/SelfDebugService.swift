//
//  SelfDebugService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

class SelfDebugService {
    // MARK: - Debug App Design
    func debugAppDesign(_ design: AppDesign, validationResult: ValidationResult) async throws -> AppDesign {
        guard !validationResult.errors.isEmpty else {
            return design
        }
        
        try await Task.sleep(nanoseconds: 120_000_000)
        return applyManualFixes(to: design, validationResult: validationResult)
    }
    
    // MARK: - Debug Generated Code
    func debugGeneratedCode(_ app: GeneratedApp, runtimeError: String) async throws -> GeneratedApp {
        try await Task.sleep(nanoseconds: 100_000_000)
        
        var html = app.html
        var css = app.css
        var javascript = app.javascript
        
        if !html.contains("data-testid=\"root\"") {
            html = """
            <div data-testid="root">
                \(html)
            </div>
            """
        }
        
        if !css.contains("body") {
            css = """
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f7fb; margin: 0; padding: 0; }
            \(css)
            """
        }
        
        if runtimeError.lowercased().contains("script") && !javascript.contains("document.addEventListener") {
            javascript = """
            document.addEventListener('DOMContentLoaded', () => {
                \(javascript)
            });
            """
        }
        
        return GeneratedApp(
            id: app.id,
            name: app.name,
            html: html,
            css: css,
            javascript: javascript,
            metadata: app.metadata
        )
    }
    
    // MARK: - Improve App Design
    func improveAppDesign(_ design: AppDesign, suggestions: [String]) async throws -> AppDesign {
        try await Task.sleep(nanoseconds: 80_000_000)
        var improved = applyManualFixes(
            to: design,
            validationResult: ValidationResult(isValid: true, errors: [], warnings: [], score: 1.0)
        )
        improved.rootComponent.style.backgroundColor = "#F4F6FB"
        improved.metadata.updatedAt = Date()
        return improved
    }
    
    // MARK: - Private Helpers
    private func applyManualFixes(to design: AppDesign, validationResult: ValidationResult) -> AppDesign {
        var fixedDesign = design
        
        func fixComponent(_ component: inout AppComponent) {
            if component.layout.width <= 0 {
                component.layout.width = 200
            }
            if component.layout.height <= 0 && component.type != .spacer {
                component.layout.height = 100
            }
            if !isValidColor(component.style.backgroundColor) {
                component.style.backgroundColor = "#FFFFFF"
            }
            if !isValidColor(component.style.textColor) {
                component.style.textColor = "#0F172A"
            }
            if component.style.opacity < 0 || component.style.opacity > 1 {
                component.style.opacity = 1.0
            }
            if component.style.fontSize <= 0 {
                component.style.fontSize = 16
            }
            if component.type == .button && (component.data.text?.isEmpty ?? true) {
                component.data.text = "Tap"
            }
            for i in 0..<component.children.count {
                fixComponent(&component.children[i])
            }
        }
        
        fixComponent(&fixedDesign.rootComponent)
        fixedDesign.metadata.updatedAt = Date()
        return fixedDesign
    }
    
    private func isValidColor(_ color: String) -> Bool {
        if color.hasPrefix("#") {
            let hex = String(color.dropFirst())
            return (hex.count == 6 || hex.count == 8) && hex.allSatisfy { $0.isHexDigit }
        }
        let namedColors = ["black", "white", "red", "green", "blue", "transparent"]
        return namedColors.contains(color.lowercased())
    }
}
