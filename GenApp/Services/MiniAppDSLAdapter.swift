//
//  MiniAppDSLAdapter.swift
//  GenApp
//
//  Created by GPT-5.1 Codex on 11/19/25.
//

import Foundation

/// Converts legacy `AppDesign` structures into the new MiniApp DSL until the backend LLM takes over.
struct MiniAppDSLAdapter {
    func convert(design: AppDesign, ownerId: String = "local-user") -> MiniAppSpec {
        var actions: [MiniAppAction] = []
        let components = design.rootComponent.children.map {
            convert(component: $0, actions: &actions)
        }
        
        let page = MiniAppPage(
            id: "page-\(design.id)",
            title: design.name,
            layout: .scroll,
            components: components
        )
        
        let versionNumber = Int(design.metadata.version.split(separator: ".").first ?? "1") ?? 1
        
        return MiniAppSpec(
            id: design.id,
            ownerId: ownerId,
            name: design.name,
            description: design.description,
            category: .utility,
            version: versionNumber,
            pages: [page],
            capabilities: inferCapabilities(from: design),
            initialState: [:],
            actions: actions,
            createdAt: design.metadata.createdAt,
            updatedAt: design.metadata.updatedAt
        )
    }
    
    // MARK: - Component conversion
    private func convert(component: AppComponent, actions: inout [MiniAppAction]) -> MiniAppComponent {
        let type = mapType(component.type)
        var props = MiniAppComponentProps(
            text: component.data.text,
            label: component.data.text,
            placeholder: component.data.placeholder,
            imageURL: component.data.imageURL,
            items: component.data.items,
            style: MiniAppComponentStyle(
                backgroundColor: component.style.backgroundColor,
                textColor: component.style.textColor,
                accentColor: component.style.backgroundColor,
                fontSize: component.style.fontSize,
                fontWeight: weight(from: component.style.fontWeight),
                cornerRadius: component.style.borderRadius,
                padding: component.layout.padding.top,
                spacing: 8,
                borderWidth: component.style.borderWidth,
                borderColor: component.style.borderColor
            )
        )
        
        if type == .button && props.label == nil {
            props.label = "Button"
        }
        
        var actionIds: [String] = []
        if type == .button {
            let actionId = "action-\(component.id)"
            actionIds.append(actionId)
            let action = MiniAppAction(
                id: actionId,
                type: .showAlert,
                params: [
                    "title": .string(props.label ?? "Button"),
                    "message": .string(component.data.action ?? "Tapped action")
                ]
            )
            actions.append(action)
        }
        
        let children = component.children.map {
            convert(component: $0, actions: &actions)
        }
        
        return MiniAppComponent(
            id: component.id,
            type: type,
            props: props,
            bindings: nil,
            actionIds: actionIds,
            children: children
        )
    }
    
    // MARK: - Helpers
    private func mapType(_ type: ComponentType) -> MiniAppComponentType {
        switch type {
        case .container: return .container
        case .text: return .label
        case .button: return .button
        case .image: return .image
        case .input: return .input
        case .list: return .list
        case .card: return .container
        case .divider: return .spacer
        case .spacer: return .spacer
        }
    }
    
    private func weight(from value: String) -> Double {
        if let numeric = Double(value) {
            return numeric
        }
        switch value.lowercased() {
        case "ultralight": return 100
        case "thin": return 200
        case "light": return 300
        case "regular": return 400
        case "medium": return 500
        case "semibold": return 600
        case "bold": return 700
        case "heavy": return 800
        default: return 400
        }
    }
    
    private func inferCapabilities(from design: AppDesign) -> [MiniAppCapability] {
        var capabilities: Set<MiniAppCapability> = []
        let description = design.description.lowercased()
        if description.contains("timer") {
            capabilities.insert(.timer)
        }
        if description.contains("flashlight") {
            capabilities.insert(.flashlight)
        }
        if description.contains("notification") {
            capabilities.insert(.localNotifications)
        }
        return Array(capabilities)
    }
}


