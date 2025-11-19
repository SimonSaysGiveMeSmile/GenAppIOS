//
//  ToolCall.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/18/25.
//

import Foundation

enum OpenAITool: String, Codable, CaseIterable {
    case promptCompression = "prompt_compression"
    case layoutPlanner = "layout_planner"
    case componentBuilder = "component_builder"
    case runtimeBootstrap = "runtime_bootstrap"
    
    var displayName: String {
        switch self {
        case .promptCompression:
            return "Prompt Analyzer"
        case .layoutPlanner:
            return "Layout Planner"
        case .componentBuilder:
            return "Component Builder"
        case .runtimeBootstrap:
            return "Runtime Bootstrap"
        }
    }
    
    var systemImage: String {
        switch self {
        case .promptCompression:
            return "text.magnifyingglass"
        case .layoutPlanner:
            return "rectangle.3.group"
        case .componentBuilder:
            return "square.stack.3d.up"
        case .runtimeBootstrap:
            return "bolt.horizontal.circle"
        }
    }
}

enum ToolCallStatus: String, Codable {
    case pending
    case running
    case completed
    case failed
}

struct ToolCallSummary: Identifiable, Codable {
    let id: String
    let tool: OpenAITool
    var inputPreview: String
    var outputSummary: String
    var status: ToolCallStatus
    var duration: TimeInterval
    
    init(id: String = UUID().uuidString,
         tool: OpenAITool,
         inputPreview: String,
         outputSummary: String = "",
         status: ToolCallStatus = .pending,
         duration: TimeInterval = 0) {
        self.id = id
        self.tool = tool
        self.inputPreview = inputPreview
        self.outputSummary = outputSummary
        self.status = status
        self.duration = duration
    }
}

struct ToolInvocationResult {
    let summary: String
    let suggestedNextStep: String
}

