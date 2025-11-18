//
//  AppValidatorService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

struct ValidationResult {
    var isValid: Bool
    var errors: [ValidationError]
    var warnings: [ValidationWarning]
    var score: Double // 0.0 to 1.0
    
    struct ValidationError {
        var componentId: String?
        var message: String
        var severity: Severity
        
        enum Severity {
            case critical
            case error
            case warning
        }
    }
    
    struct ValidationWarning {
        var componentId: String?
        var message: String
        var suggestion: String?
    }
}

class AppValidatorService {
    
    func validate(_ design: AppDesign) -> ValidationResult {
        var errors: [ValidationResult.ValidationError] = []
        var warnings: [ValidationResult.ValidationWarning] = []
        
        // Validate root component
        validateComponent(design.rootComponent, errors: &errors, warnings: &warnings)
        
        // Validate structure
        validateStructure(design, errors: &errors, warnings: &warnings)
        
        // Validate styles
        validateStyles(design, errors: &errors, warnings: &warnings)
        
        // Calculate score
        let score = calculateScore(errors: errors, warnings: warnings)
        
        return ValidationResult(
            isValid: errors.filter { $0.severity == .critical || $0.severity == .error }.isEmpty,
            errors: errors,
            warnings: warnings,
            score: score
        )
    }
    
    private func validateComponent(_ component: AppComponent, errors: inout [ValidationResult.ValidationError], warnings: inout [ValidationResult.ValidationWarning]) {
        // Validate layout
        if component.layout.width <= 0 {
            errors.append(ValidationResult.ValidationError(
                componentId: component.id,
                message: "Component has invalid width",
                severity: .error
            ))
        }
        
        if component.layout.height <= 0 && component.type != .spacer {
            errors.append(ValidationResult.ValidationError(
                componentId: component.id,
                message: "Component has invalid height",
                severity: .error
            ))
        }
        
        // Validate data based on type
        switch component.type {
        case .text:
            if component.data.text?.isEmpty ?? true {
                warnings.append(ValidationResult.ValidationWarning(
                    componentId: component.id,
                    message: "Text component is empty",
                    suggestion: "Add some text content"
                ))
            }
            
        case .button:
            if component.data.text?.isEmpty ?? true {
                errors.append(ValidationResult.ValidationError(
                    componentId: component.id,
                    message: "Button must have text",
                    severity: .error
                ))
            }
            
        case .image:
            if component.data.imageURL?.isEmpty ?? true {
                warnings.append(ValidationResult.ValidationWarning(
                    componentId: component.id,
                    message: "Image component has no source URL",
                    suggestion: "Add an image URL or use a placeholder"
                ))
            }
            
        case .input:
            break // Inputs are valid even without placeholder
            
        case .list:
            if component.data.items?.isEmpty ?? true {
                warnings.append(ValidationResult.ValidationWarning(
                    componentId: component.id,
                    message: "List component is empty",
                    suggestion: "Add items to the list"
                ))
            }
            
        default:
            break
        }
        
        // Recursively validate children
        for child in component.children {
            validateComponent(child, errors: &errors, warnings: &warnings)
        }
    }
    
    private func validateStructure(_ design: AppDesign, errors: inout [ValidationResult.ValidationError], warnings: inout [ValidationResult.ValidationWarning]) {
        // Check for orphaned components
        let allComponents = getAllComponents(design.rootComponent)
        let componentIds = Set(allComponents.map { $0.id })
        
        for component in allComponents {
            if let parentId = component.parentId, !componentIds.contains(parentId) {
                errors.append(ValidationResult.ValidationError(
                    componentId: component.id,
                    message: "Component references non-existent parent",
                    severity: .error
                ))
            }
        }
        
        // Check for duplicate IDs
        let ids = allComponents.map { $0.id }
        let uniqueIds = Set(ids)
        if ids.count != uniqueIds.count {
            errors.append(ValidationResult.ValidationError(
                componentId: nil,
                message: "Duplicate component IDs found",
                severity: .critical
            ))
        }
    }
    
    private func validateStyles(_ design: AppDesign, errors: inout [ValidationResult.ValidationError], warnings: inout [ValidationResult.ValidationWarning]) {
        let allComponents = getAllComponents(design.rootComponent)
        
        for component in allComponents {
            // Validate color formats
            if !isValidColor(component.style.backgroundColor) {
                errors.append(ValidationResult.ValidationError(
                    componentId: component.id,
                    message: "Invalid background color format",
                    severity: .error
                ))
            }
            
            if !isValidColor(component.style.textColor) {
                errors.append(ValidationResult.ValidationError(
                    componentId: component.id,
                    message: "Invalid text color format",
                    severity: .error
                ))
            }
            
            // Validate opacity
            if component.style.opacity < 0 || component.style.opacity > 1 {
                errors.append(ValidationResult.ValidationError(
                    componentId: component.id,
                    message: "Opacity must be between 0 and 1",
                    severity: .error
                ))
            }
            
            // Validate font size
            if component.style.fontSize <= 0 {
                errors.append(ValidationResult.ValidationError(
                    componentId: component.id,
                    message: "Font size must be greater than 0",
                    severity: .error
                ))
            }
        }
    }
    
    private func isValidColor(_ color: String) -> Bool {
        // Check hex color format (#RRGGBB or #RRGGBBAA)
        if color.hasPrefix("#") {
            let hex = String(color.dropFirst())
            return (hex.count == 6 || hex.count == 8) && hex.allSatisfy { $0.isHexDigit }
        }
        
        // Check named colors (basic check)
        let namedColors = ["black", "white", "red", "green", "blue", "transparent"]
        return namedColors.contains(color.lowercased())
    }
    
    private func getAllComponents(_ component: AppComponent) -> [AppComponent] {
        var components = [component]
        for child in component.children {
            components.append(contentsOf: getAllComponents(child))
        }
        return components
    }
    
    private func calculateScore(errors: [ValidationResult.ValidationError], warnings: [ValidationResult.ValidationWarning]) -> Double {
        let criticalErrors = errors.filter { $0.severity == .critical }.count
        let regularErrors = errors.filter { $0.severity == .error }.count
        let warningCount = warnings.count
        
        // Start with perfect score
        var score = 1.0
        
        // Deduct for errors
        score -= Double(criticalErrors) * 0.3
        score -= Double(regularErrors) * 0.1
        score -= Double(warningCount) * 0.05
        
        // Ensure score is between 0 and 1
        return max(0.0, min(1.0, score))
    }
}

extension Character {
    var isHexDigit: Bool {
        return ("0"..."9").contains(self) || ("a"..."f").contains(self) || ("A"..."F").contains(self)
    }
}

