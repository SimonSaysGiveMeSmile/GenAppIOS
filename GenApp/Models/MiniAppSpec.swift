//
//  MiniAppSpec.swift
//  GenApp
//
//  Created by GPT-5.1 Codex on 11/19/25.
//

import Foundation
import SwiftUI

/// Canonical DSL model describing a renderable MiniApp.
struct MiniAppSpec: Identifiable, Codable {
    let id: String
    let ownerId: String
    let name: String
    let description: String
    let category: MiniAppCategory
    let version: Int
    let pages: [MiniAppPage]
    let capabilities: [MiniAppCapability]
    let initialState: [String: MiniAppValue]
    let actions: [MiniAppAction]
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String,
        ownerId: String,
        name: String,
        description: String,
        category: MiniAppCategory = .utility,
        version: Int = 1,
        pages: [MiniAppPage],
        capabilities: [MiniAppCapability] = [],
        initialState: [String: MiniAppValue] = [:],
        actions: [MiniAppAction] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.description = description
        self.category = category
        self.version = version
        self.pages = pages
        self.capabilities = capabilities
        self.initialState = initialState
        self.actions = actions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum MiniAppCategory: String, Codable {
    case utility
    case learning
    case productivity
    case wellness
    case entertainment
    case finance
}

enum MiniAppCapability: String, Codable {
    case flashlight = "FLASHLIGHT"
    case timer = "TIMER"
    case localNotifications = "LOCAL_NOTIFICATIONS"
    case haptics = "HAPTICS"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Normalize to uppercase and handle common variations
        let normalized = rawValue.uppercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        
        // Map common variations
        let mapping: [String: String] = [
            "FLASHLIGHT": "FLASHLIGHT",
            "TIMER": "TIMER",
            "LOCAL_NOTIFICATIONS": "LOCAL_NOTIFICATIONS",
            "LOCALNOTIFICATIONS": "LOCAL_NOTIFICATIONS",
            "NOTIFICATIONS": "LOCAL_NOTIFICATIONS",
            "HAPTICS": "HAPTICS",
            "HAPTIC": "HAPTICS"
        ]
        
        let mappedValue = mapping[normalized] ?? normalized
        
        guard let capability = MiniAppCapability(rawValue: mappedValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot initialize MiniAppCapability from invalid String value '\(rawValue)'"
            )
        }
        
        self = capability
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct MiniAppPage: Identifiable, Codable {
    let id: String
    let title: String?
    let layout: MiniAppPageLayout
    let components: [MiniAppComponent]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case layout
        case components
    }
    
    init(id: String, title: String? = nil, layout: MiniAppPageLayout = .scroll, components: [MiniAppComponent]) {
        self.id = id
        self.title = title
        self.layout = layout
        self.components = components
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        // Handle both "title" and "name" fields for backward compatibility
        if let titleValue = try? container.decodeIfPresent(String.self, forKey: .title) {
            title = titleValue
        } else {
            // Try to decode "name" as a fallback
            let allKeys = container.allKeys
            if let nameKey = allKeys.first(where: { $0.stringValue == "name" }) {
                title = try? container.decode(String.self, forKey: nameKey)
            } else {
                title = nil
            }
        }
        // Default to .scroll if layout is missing
        layout = try container.decodeIfPresent(MiniAppPageLayout.self, forKey: .layout) ?? .scroll
        components = try container.decode([MiniAppComponent].self, forKey: .components)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(layout, forKey: .layout)
        try container.encode(components, forKey: .components)
    }
}

enum MiniAppPageLayout: String, Codable {
    case scroll
    case center
    case grid
}

struct MiniAppComponent: Identifiable, Codable {
    let id: String
    let type: MiniAppComponentType
    var props: MiniAppComponentProps
    var bindings: MiniAppBinding?
    var actionIds: [String]
    var children: [MiniAppComponent]
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case props
        case bindings
        case actionIds
        case children
    }
    
    init(
        id: String = UUID().uuidString,
        type: MiniAppComponentType,
        props: MiniAppComponentProps = MiniAppComponentProps(),
        bindings: MiniAppBinding? = nil,
        actionIds: [String] = [],
        children: [MiniAppComponent] = []
    ) {
        self.id = id
        self.type = type
        self.props = props
        self.bindings = bindings
        self.actionIds = actionIds
        self.children = children
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Generate ID if missing
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        type = try container.decode(MiniAppComponentType.self, forKey: .type)
        props = try container.decodeIfPresent(MiniAppComponentProps.self, forKey: .props) ?? MiniAppComponentProps()
        bindings = try container.decodeIfPresent(MiniAppBinding.self, forKey: .bindings)
        actionIds = try container.decodeIfPresent([String].self, forKey: .actionIds) ?? []
        children = try container.decodeIfPresent([MiniAppComponent].self, forKey: .children) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(props, forKey: .props)
        try container.encodeIfPresent(bindings, forKey: .bindings)
        try container.encode(actionIds, forKey: .actionIds)
        try container.encode(children, forKey: .children)
    }
}

enum MiniAppComponentType: String, Codable {
    case container
    case label
    case button
    case toggle
    case image
    case timerDisplay
    case list
    case input
    case quizQuestion
    case spacer
}

struct MiniAppComponentProps: Codable {
    var text: String?
    var label: String?
    var placeholder: String?
    var imageURL: String?
    var items: [String]?
    var style: MiniAppComponentStyle
    var value: MiniAppValue?
    var options: [String]?
    var layoutHint: MiniAppComponentLayoutHint
    
    init(
        text: String? = nil,
        label: String? = nil,
        placeholder: String? = nil,
        imageURL: String? = nil,
        items: [String]? = nil,
        style: MiniAppComponentStyle = .defaultStyle,
        value: MiniAppValue? = nil,
        options: [String]? = nil,
        layoutHint: MiniAppComponentLayoutHint = .block
    ) {
        self.text = text
        self.label = label
        self.placeholder = placeholder
        self.imageURL = imageURL
        self.items = items
        self.style = style
        self.value = value
        self.options = options
        self.layoutHint = layoutHint
    }
}

struct MiniAppComponentStyle: Codable {
    var backgroundColor: String
    var textColor: String
    var accentColor: String
    var fontSize: Double
    var fontWeight: Double
    var cornerRadius: Double
    var padding: Double
    var spacing: Double
    var borderWidth: Double
    var borderColor: String
    
    enum CodingKeys: String, CodingKey {
        case backgroundColor
        case textColor
        case accentColor
        case fontSize
        case fontWeight
        case cornerRadius
        case padding
        case spacing
        case borderWidth
        case borderColor
    }
    
    init(
        backgroundColor: String,
        textColor: String,
        accentColor: String,
        fontSize: Double,
        fontWeight: Double,
        cornerRadius: Double,
        padding: Double,
        spacing: Double,
        borderWidth: Double,
        borderColor: String
    ) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.accentColor = accentColor
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.spacing = spacing
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }
    
    static var defaultStyle: MiniAppComponentStyle {
        MiniAppComponentStyle(
            backgroundColor: "#FFFFFF",
            textColor: "#0F172A",
            accentColor: "#2563EB",
            fontSize: 16,
            fontWeight: 400,
            cornerRadius: 14,
            padding: 12,
            spacing: 8,
            borderWidth: 0,
            borderColor: "#000000"
        )
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        backgroundColor = try container.decode(String.self, forKey: .backgroundColor)
        textColor = try container.decode(String.self, forKey: .textColor)
        accentColor = try container.decode(String.self, forKey: .accentColor)
        
        // Validate and sanitize numeric values to prevent NaN/infinite
        let defaultStyle = Self.defaultStyle
        fontSize = Self.sanitizeDouble(try container.decode(Double.self, forKey: .fontSize), fallback: defaultStyle.fontSize)
        fontWeight = Self.sanitizeDouble(try container.decode(Double.self, forKey: .fontWeight), fallback: defaultStyle.fontWeight)
        cornerRadius = Self.sanitizeDouble(try container.decode(Double.self, forKey: .cornerRadius), fallback: defaultStyle.cornerRadius)
        padding = Self.sanitizeDouble(try container.decode(Double.self, forKey: .padding), fallback: defaultStyle.padding)
        spacing = Self.sanitizeDouble(try container.decode(Double.self, forKey: .spacing), fallback: defaultStyle.spacing)
        borderWidth = Self.sanitizeDouble(try container.decode(Double.self, forKey: .borderWidth), fallback: defaultStyle.borderWidth)
        borderColor = try container.decode(String.self, forKey: .borderColor)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(backgroundColor, forKey: .backgroundColor)
        try container.encode(textColor, forKey: .textColor)
        try container.encode(accentColor, forKey: .accentColor)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(fontWeight, forKey: .fontWeight)
        try container.encode(cornerRadius, forKey: .cornerRadius)
        try container.encode(padding, forKey: .padding)
        try container.encode(spacing, forKey: .spacing)
        try container.encode(borderWidth, forKey: .borderWidth)
        try container.encode(borderColor, forKey: .borderColor)
    }
    
    private static func sanitizeDouble(_ value: Double, fallback: Double) -> Double {
        return value.isFinite && !value.isNaN ? value : fallback
    }
}

enum MiniAppComponentLayoutHint: String, Codable {
    case block
    case inline
    case hero
}

struct MiniAppBinding: Codable {
    var stateKey: String
}

struct MiniAppAction: Identifiable, Codable {
    let id: String
    let type: MiniAppActionType
    var params: [String: MiniAppValue]
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case params
    }
    
    init(id: String = UUID().uuidString, type: MiniAppActionType, params: [String: MiniAppValue] = [:]) {
        self.id = id
        self.type = type
        self.params = params
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Generate ID if missing
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        type = try container.decode(MiniAppActionType.self, forKey: .type)
        // Default to empty dictionary if params is missing
        params = try container.decodeIfPresent([String: MiniAppValue].self, forKey: .params) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(params, forKey: .params)
    }
}

enum MiniAppActionType: String, Codable {
    case navigate = "NAVIGATE"
    case toggleFlashlight = "TOGGLE_FLASHLIGHT"
    case startTimer = "START_TIMER"
    case showAlert = "SHOW_ALERT"
    case setState = "SET_STATE"
}

struct MiniAppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

/// JSON value representation backed by Codable.
enum MiniAppValue: Codable, Equatable {
    case string(String)
    case double(Double)
    case bool(Bool)
    case dictionary([String: MiniAppValue])
    case array([MiniAppValue])
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let dictionaryValue = try? container.decode([String: MiniAppValue].self) {
            self = .dictionary(dictionaryValue)
        } else if let arrayValue = try? container.decode([MiniAppValue].self) {
            self = .array(arrayValue)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
    
    var stringValue: String? {
        switch self {
        case .string(let value): return value
        case .double(let value): return String(value)
        case .bool(let value): return value ? "true" : "false"
        default: return nil
        }
    }
    
    var boolValue: Bool? {
        switch self {
        case .bool(let value): return value
        case .string(let value): return (value as NSString).boolValue
        default: return nil
        }
    }
    
    var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .string(let value): return Double(value)
        default: return nil
        }
    }
}


