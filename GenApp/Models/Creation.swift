//
//  Creation.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

enum CreationType: String, Codable {
    case app
    case illustration
    case answer
    case reference
}

struct Creation: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let description: String
    let type: CreationType
    let content: String // JSON or text content
    let thumbnailURL: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, userId: String, title: String, description: String, type: CreationType, content: String, thumbnailURL: String? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.type = type
        self.content = content
        self.thumbnailURL = thumbnailURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

