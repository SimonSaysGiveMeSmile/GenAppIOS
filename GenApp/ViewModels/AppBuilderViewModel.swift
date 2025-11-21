//
//  AppBuilderViewModel.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation
import SwiftUI

@MainActor
class AppBuilderViewModel: ObservableObject {
    @Published var currentDesign: AppDesign
    @Published var selectedComponent: AppComponent?
    @Published var showPropertiesPanel = false
    @Published var isRunning = false
    
    private let orchestrator: AppBuilderOrchestrator
    private let storageService: StorageService
    let userId: String
    
    init(orchestrator: AppBuilderOrchestrator, storageService: StorageService, userId: String) {
        // Create a default empty app design
        let rootComponent = AppComponent(
            type: .container,
            layout: LayoutProperties(width: 375, height: 812), // iPhone size
            style: StyleProperties(backgroundColor: "#FFFFFF")
        )
        
        self.currentDesign = AppDesign(
            name: "New App",
            description: "A new app design",
            rootComponent: rootComponent
        )
        
        self.orchestrator = orchestrator
        self.storageService = storageService
        self.userId = userId
    }
    
    // MARK: - Component Management
    func addComponent(_ component: AppComponent, to parentId: String?) {
        if let parentId = parentId {
            addComponentToParent(component, parentId: parentId)
        } else {
            // Add to root
            currentDesign.rootComponent.children.append(component)
        }
        updateDesign()
    }
    
    func removeComponent(_ componentId: String) {
        removeComponentFromTree(componentId, in: &currentDesign.rootComponent)
        if selectedComponent?.id == componentId {
            selectedComponent = nil
            showPropertiesPanel = false
        }
        updateDesign()
    }
    
    func updateComponent(_ component: AppComponent) {
        updateComponentInTree(component, in: &currentDesign.rootComponent)
        if selectedComponent?.id == component.id {
            selectedComponent = component
        }
        updateDesign()
    }
    
    func selectComponent(_ component: AppComponent) {
        selectedComponent = component
        showPropertiesPanel = true
    }
    
    // MARK: - Build & Run
    func buildAndRun() async {
        isRunning = true
        await orchestrator.runFullCycle(design: currentDesign, autoDebug: true)
        isRunning = false
    }
    
    func saveApp() {
        guard let miniApp = orchestrator.generatedMiniApp else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let content: String
        if let data = try? encoder.encode(miniApp),
           let json = String(data: data, encoding: .utf8) {
            content = json
        } else {
            content = "{}"
        }
        
        let creation = Creation(
            userId: userId,
            title: currentDesign.name,
            description: currentDesign.description,
            type: .app,
            content: content
        )
        
        storageService.saveCreation(creation)
    }
    
    // MARK: - Private Helpers
    private func updateDesign() {
        currentDesign.metadata.updatedAt = Date()
        orchestrator.currentDesign = currentDesign
    }
    
    private func addComponentToParent(_ component: AppComponent, parentId: String) {
        if currentDesign.rootComponent.id == parentId {
            currentDesign.rootComponent.children.append(component)
            return
        }
        
        func addToComponent(_ comp: inout AppComponent) {
            if comp.id == parentId {
                comp.children.append(component)
            } else {
                for i in 0..<comp.children.count {
                    addToComponent(&comp.children[i])
                }
            }
        }
        
        addToComponent(&currentDesign.rootComponent)
    }
    
    private func removeComponentFromTree(_ componentId: String, in component: inout AppComponent) {
        component.children.removeAll { $0.id == componentId }
        for i in 0..<component.children.count {
            removeComponentFromTree(componentId, in: &component.children[i])
        }
    }
    
    private func updateComponentInTree(_ component: AppComponent, in root: inout AppComponent) {
        if root.id == component.id {
            root = component
            return
        }
        
        for i in 0..<root.children.count {
            if root.children[i].id == component.id {
                root.children[i] = component
            } else {
                updateComponentInTree(component, in: &root.children[i])
            }
        }
    }
}

