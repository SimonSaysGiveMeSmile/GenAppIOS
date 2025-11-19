//
//  CodeGeneratorService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation
import CoreGraphics

class CodeGeneratorService {
    
    // MARK: - Generate Complete App
    func generateApp(from design: AppDesign) -> GeneratedApp {
        let html = generateHTML(from: design)
        let css = generateCSS(from: design)
        let js = generateJavaScript(from: design)
        
        return GeneratedApp(
            id: design.id,
            name: design.name,
            html: html,
            css: css,
            javascript: js,
            metadata: design.metadata
        )
    }
    
    // MARK: - HTML Generation
    private func generateHTML(from design: AppDesign) -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(design.name)</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
            </style>
            <link rel="stylesheet" href="app-styles.css">
        </head>
        <body>
            <div id="app-root">
        """
        
        html += generateComponentHTML(design.rootComponent, indent: 2)
        
        html += """
            </div>
            <script src="app-script.js"></script>
        </body>
        </html>
        """
        
        return html
    }
    
    private func generateComponentHTML(_ component: AppComponent, indent: Int) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        var html = ""
        
        let elementId = "component-\(component.id)"
        let elementClass = "component-\(component.type.rawValue.lowercased())"
        
        switch component.type {
        case .container:
            html += "\(indentStr)<div id=\"\(elementId)\" class=\"\(elementClass)\">\n"
            for child in component.children {
                html += generateComponentHTML(child, indent: indent + 1)
            }
            html += "\(indentStr)</div>\n"
            
        case .text:
            html += "\(indentStr)<p id=\"\(elementId)\" class=\"\(elementClass)\">\(component.data.text ?? "")</p>\n"
            
        case .button:
            let action = component.data.action ?? "handleClick"
            html += "\(indentStr)<button id=\"\(elementId)\" class=\"\(elementClass)\" onclick=\"\(action)('\(component.id)')\">\(component.data.text ?? "Button")</button>\n"
            
        case .image:
            let src = component.data.imageURL ?? "https://via.placeholder.com/\(Int(component.layout.width))x\(Int(component.layout.height))"
            html += "\(indentStr)<img id=\"\(elementId)\" class=\"\(elementClass)\" src=\"\(src)\" alt=\"\(component.data.text ?? "")\">\n"
            
        case .input:
            let placeholder = component.data.placeholder ?? ""
            html += "\(indentStr)<input id=\"\(elementId)\" class=\"\(elementClass)\" type=\"text\" placeholder=\"\(placeholder)\" value=\"\(component.data.value ?? "")\">\n"
            
        case .list:
            html += "\(indentStr)<ul id=\"\(elementId)\" class=\"\(elementClass)\">\n"
            for item in component.data.items ?? [] {
                html += "\(indentStr)  <li>\(item)</li>\n"
            }
            html += "\(indentStr)</ul>\n"
            
        case .card:
            html += "\(indentStr)<div id=\"\(elementId)\" class=\"\(elementClass) card\">\n"
            if let title = component.data.text {
                html += "\(indentStr)  <h3 class=\"card-title\">\(title)</h3>\n"
            }
            for child in component.children {
                html += generateComponentHTML(child, indent: indent + 1)
            }
            html += "\(indentStr)</div>\n"
            
        case .divider:
            html += "\(indentStr)<hr id=\"\(elementId)\" class=\"\(elementClass)\">\n"
            
        case .spacer:
            html += "\(indentStr)<div id=\"\(elementId)\" class=\"\(elementClass) spacer\"></div>\n"
        }
        
        return html
    }
    
    // MARK: - CSS Generation
    private func generateCSS(from design: AppDesign) -> String {
        var css = "/* Generated CSS for \(design.name) */\n\n"
        css += generateComponentCSS(design.rootComponent)
        return css
    }
    
    private func generateComponentCSS(_ component: AppComponent) -> String {
        var css = ""
        let selector = "#component-\(component.id)"
        
        // Layout
        css += "\(selector) {\n"
        css += "  position: relative;\n"
        css += "  width: \(safe(component.layout.width, fallback: 320))px;\n"
        css += "  height: \(safe(component.layout.height, fallback: 48))px;\n"
        css += "  padding: \(safe(component.layout.padding.top, fallback: 0))px \(safe(component.layout.padding.trailing, fallback: 0))px \(safe(component.layout.padding.bottom, fallback: 0))px \(safe(component.layout.padding.leading, fallback: 0))px;\n"
        css += "  margin: \(safe(component.layout.margin.top, fallback: 0))px \(safe(component.layout.margin.trailing, fallback: 0))px \(safe(component.layout.margin.bottom, fallback: 12))px \(safe(component.layout.margin.leading, fallback: 0))px;\n"
        
        // Style
        css += "  background-color: \(component.style.backgroundColor);\n"
        css += "  color: \(component.style.textColor);\n"
        css += "  font-size: \(safe(component.style.fontSize, fallback: 16))px;\n"
        css += "  font-weight: \(component.style.fontWeight);\n"
        if component.style.fontFamily != "system" {
            css += "  font-family: \(component.style.fontFamily);\n"
        }
        css += "  border-radius: \(safe(component.style.borderRadius, fallback: 0))px;\n"
        css += "  border: \(safe(component.style.borderWidth, fallback: 0))px solid \(component.style.borderColor);\n"
        css += "  opacity: \(safe(component.style.opacity, fallback: 1.0));\n"
        
        if let shadow = component.style.shadow {
            css += "  box-shadow: \(safe(shadow.offsetX, fallback: 0))px \(safe(shadow.offsetY, fallback: 0))px \(safe(shadow.radius, fallback: 4))px \(shadow.color);\n"
        }
        
        css += "}\n\n"
        
        // Recursively generate CSS for children
        for child in component.children {
            css += generateComponentCSS(child)
        }
        
        return css
    }
    
    // MARK: - JavaScript Generation
    private func generateJavaScript(from design: AppDesign) -> String {
        var js = """
        // Generated JavaScript for \(design.name)
        
        // Initialize app
        document.addEventListener('DOMContentLoaded', function() {
            console.log('App loaded: \(design.name)');
            initializeApp();
        });
        
        function initializeApp() {
            // Auto-generated initialization code
        }
        
        """
        
        // Generate event handlers for interactive components
        js += generateComponentJavaScript(design.rootComponent)
        
        // Default handlers
        js += """
        
        // Default click handler
        function handleClick(componentId) {
            console.log('Clicked component:', componentId);
            // Add custom behavior here
        }
        
        // Default input handler
        function handleInput(componentId, value) {
            console.log('Input changed:', componentId, value);
            // Add custom behavior here
        }
        """
        
        return js
    }
    
    private func generateComponentJavaScript(_ component: AppComponent) -> String {
        var js = ""
        
        switch component.type {
        case .button:
            if let action = component.data.action, action != "handleClick" {
                js += """
                function \(action)(componentId) {
                    // Custom action for \(component.id)
                    console.log('Custom action: \(action)');
                }
                
                """
            }
            
        case .input:
            js += """
            document.getElementById('component-\(component.id)').addEventListener('input', function(e) {
                handleInput('\(component.id)', e.target.value);
            });
            
            """
            
        default:
            break
        }
        
        // Recursively generate JS for children
        for child in component.children {
            js += generateComponentJavaScript(child)
        }
        
        return js
    }
}

// MARK: - Helpers
private func safe(_ value: Double, fallback: Double) -> Double {
    value.isFinite ? value : fallback
}

private func safe(_ value: CGFloat, fallback: Double) -> Double {
    let doubleValue = Double(value)
    return doubleValue.isFinite ? doubleValue : fallback
}

// MARK: - Generated App
struct GeneratedApp: Codable {
    let id: String
    let name: String
    let html: String
    let css: String
    let javascript: String
    let metadata: AppDesign.AppMetadata
}

