//
//  ChatMessage.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
    case log
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String
    var createdAt: Date
    
    init(id: String = UUID().uuidString, role: MessageRole, content: String) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = Date()
    }
}

