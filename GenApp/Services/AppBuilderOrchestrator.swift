//
//  AppBuilderOrchestrator.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation
import Combine

@MainActor
class AppBuilderOrchestrator: ObservableObject {
    @Published var currentDesign: AppDesign?
    @Published var generatedApp: GeneratedApp?
    @Published var validationResult: ValidationResult?
    @Published var isBuilding = false
    @Published var buildProgress: Double = 0.0
    @Published var buildStatus: BuildStatus = .idle
    @Published var detailedStatus: String = ""
    @Published var errorMessage: String?
    
    enum BuildStatus {
        case idle
        case designing
        case generating
        case validating
        case debugging
        case running
        case completed
        case failed
    }
    
    private let codeGenerator = CodeGeneratorService()
    private let validator = AppValidatorService()
    let runtimeService: AppRuntimeService
    private let debugService: SelfDebugService
    
    init(runtimeService: AppRuntimeService) {
        self.runtimeService = runtimeService
        self.debugService = SelfDebugService()
    }
    
    // MARK: - Full Automation Cycle
    func runFullCycle(design: AppDesign, autoDebug: Bool = true) async {
        isBuilding = true
        buildProgress = 0.0
        errorMessage = nil
        detailedStatus = "Starting build process..."
        
        // Step 1: Validate Design
        buildStatus = .validating
        buildProgress = 0.1
        detailedStatus = "Validating app design structure..."
        let validation = validator.validate(design)
        validationResult = validation
        
        if !validation.isValid {
            let issuesCount = validation.errors.count + validation.warnings.count
            detailedStatus = "Found \(issuesCount) issue\(issuesCount == 1 ? "" : "s") in design"
        } else {
            detailedStatus = "Design validation passed ✓"
        }
        
        // Step 2: Auto-debug if needed
        var finalDesign = design
        if autoDebug && !validation.isValid {
            do {
                buildStatus = .debugging
                buildProgress = 0.3
                detailedStatus = "Auto-fixing design issues..."
                finalDesign = try await debugService.debugAppDesign(design, validationResult: validation)
                // Re-validate after debugging
                buildProgress = 0.4
                detailedStatus = "Re-validating fixed design..."
                validationResult = validator.validate(finalDesign)
                if validationResult?.isValid == true {
                    detailedStatus = "Design issues fixed ✓"
                }
            } catch {
                buildStatus = .failed
                errorMessage = error.localizedDescription
                detailedStatus = "Build failed during debugging: \(error.localizedDescription)"
                isBuilding = false
                return
            }
        }
        
        currentDesign = finalDesign
        
        // Step 3: Generate Code
        buildStatus = .generating
        buildProgress = 0.5
        detailedStatus = "Generating HTML structure..."
        await Task.yield()
        
        buildProgress = 0.6
        detailedStatus = "Generating CSS styles..."
        await Task.yield()
        
        buildProgress = 0.7
        detailedStatus = "Generating JavaScript logic..."
        let generated = codeGenerator.generateApp(from: finalDesign)
        generatedApp = generated
        detailedStatus = "Code generation complete ✓"
        
        // Step 4: Validate Generated Code
        buildProgress = 0.8
        detailedStatus = "Preparing app runtime..."
        await Task.yield()
        
        // Step 5: Run App
        buildStatus = .running
        buildProgress = 0.9
        detailedStatus = "Launching app..."
        runtimeService.runApp(generated)
        
        buildStatus = .completed
        buildProgress = 1.0
        detailedStatus = "App build complete! ✓"
        
        isBuilding = false
    }
    
    // MARK: - Individual Steps
    func validateDesign(_ design: AppDesign) {
        validationResult = validator.validate(design)
    }
    
    func generateCode(from design: AppDesign) {
        generatedApp = codeGenerator.generateApp(from: design)
    }
    
    func runApp(_ app: GeneratedApp) {
        runtimeService.runApp(app)
        buildStatus = .running
    }
    
    func debugAndRetry() async {
        guard let design = currentDesign,
              let validation = validationResult else { return }
        
        do {
            buildStatus = .debugging
            let fixedDesign = try await debugService.debugAppDesign(design, validationResult: validation)
            currentDesign = fixedDesign
            
            // Re-run the cycle
            await runFullCycle(design: fixedDesign, autoDebug: false)
        } catch {
            errorMessage = error.localizedDescription
            buildStatus = .failed
        }
    }
    
    func improveDesign(suggestions: [String]) async {
        guard let design = currentDesign else { return }
        
        do {
            buildStatus = .designing
            let improvedDesign = try await debugService.improveAppDesign(design, suggestions: suggestions)
            currentDesign = improvedDesign
            
            // Re-run validation
            validateDesign(improvedDesign)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func reset() {
        currentDesign = nil
        generatedApp = nil
        validationResult = nil
        buildStatus = .idle
        buildProgress = 0.0
        detailedStatus = ""
        errorMessage = nil
        runtimeService.stopApp()
    }
}

