//
//  AppComponent.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation
import SwiftUI

// MARK: - Component Types
enum ComponentType: String, Codable, CaseIterable {
    case container = "Container"
    case text = "Text"
    case button = "Button"
    case image = "Image"
    case input = "Input"
    case list = "List"
    case card = "Card"
    case divider = "Divider"
    case spacer = "Spacer"
}

// MARK: - Layout Properties
struct LayoutProperties: Codable {
    var x: Double = 0
    var y: Double = 0
    var width: Double = 200
    var height: Double = 100
    var padding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    var margin: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    
    enum CodingKeys: String, CodingKey {
        case x, y, width, height
        case paddingTop, paddingLeading, paddingBottom, paddingTrailing
        case marginTop, marginLeading, marginBottom, marginTrailing
    }
    
    init(x: Double = 0, y: Double = 0, width: Double = 200, height: Double = 100,
         padding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
         margin: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.padding = padding
        self.margin = margin
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decode(Double.self, forKey: .height)
        
        let paddingTop = try container.decode(Double.self, forKey: .paddingTop)
        let paddingLeading = try container.decode(Double.self, forKey: .paddingLeading)
        let paddingBottom = try container.decode(Double.self, forKey: .paddingBottom)
        let paddingTrailing = try container.decode(Double.self, forKey: .paddingTrailing)
        padding = EdgeInsets(top: paddingTop, leading: paddingLeading, bottom: paddingBottom, trailing: paddingTrailing)
        
        let marginTop = try container.decode(Double.self, forKey: .marginTop)
        let marginLeading = try container.decode(Double.self, forKey: .marginLeading)
        let marginBottom = try container.decode(Double.self, forKey: .marginBottom)
        let marginTrailing = try container.decode(Double.self, forKey: .marginTrailing)
        margin = EdgeInsets(top: marginTop, leading: marginLeading, bottom: marginBottom, trailing: marginTrailing)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(padding.top, forKey: .paddingTop)
        try container.encode(padding.leading, forKey: .paddingLeading)
        try container.encode(padding.bottom, forKey: .paddingBottom)
        try container.encode(padding.trailing, forKey: .paddingTrailing)
        try container.encode(margin.top, forKey: .marginTop)
        try container.encode(margin.leading, forKey: .marginLeading)
        try container.encode(margin.bottom, forKey: .marginBottom)
        try container.encode(margin.trailing, forKey: .marginTrailing)
    }
}

// MARK: - Style Properties
struct StyleProperties: Codable {
    var backgroundColor: String = "#FFFFFF"
    var textColor: String = "#000000"
    var fontSize: Double = 16
    var fontWeight: String = "normal" // normal, bold, 100-900
    var fontFamily: String = "system"
    var borderRadius: Double = 0
    var borderWidth: Double = 0
    var borderColor: String = "#000000"
    var opacity: Double = 1.0
    var shadow: ShadowProperties?
    
    struct ShadowProperties: Codable {
        var color: String = "#000000"
        var radius: Double = 4
        var offsetX: Double = 0
        var offsetY: Double = 2
    }
}

// MARK: - Component Data
struct ComponentData: Codable {
    var text: String?
    var placeholder: String?
    var imageURL: String?
    var action: String? // JavaScript function name or URL
    var items: [String]? // For lists
    var value: String? // For inputs
}

// MARK: - App Component
struct AppComponent: Identifiable, Codable {
    let id: String
    var type: ComponentType
    var layout: LayoutProperties
    var style: StyleProperties
    var data: ComponentData
    var children: [AppComponent] // For containers
    var parentId: String? // Reference to parent container
    
    init(id: String = UUID().uuidString,
         type: ComponentType,
         layout: LayoutProperties = LayoutProperties(),
         style: StyleProperties = StyleProperties(),
         data: ComponentData = ComponentData(),
         children: [AppComponent] = [],
         parentId: String? = nil) {
        self.id = id
        self.type = type
        self.layout = layout
        self.style = style
        self.data = data
        self.children = children
        self.parentId = parentId
    }
}

// MARK: - App Design (Complete App Structure)
struct AppDesign: Codable {
    var id: String
    var name: String
    var description: String
    var rootComponent: AppComponent
    var globalStyles: [String: StyleProperties] // Named style presets
    var metadata: AppMetadata
    
    struct AppMetadata: Codable {
        var createdAt: Date
        var updatedAt: Date
        var version: String
        var author: String?
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         rootComponent: AppComponent,
         globalStyles: [String: StyleProperties] = [:],
         metadata: AppMetadata? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.rootComponent = rootComponent
        self.globalStyles = globalStyles
        self.metadata = metadata ?? AppMetadata(
            createdAt: Date(),
            updatedAt: Date(),
            version: "1.0.0",
            author: nil
        )
    }
}

