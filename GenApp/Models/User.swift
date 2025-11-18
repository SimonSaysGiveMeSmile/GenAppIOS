//
//  User.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String?
    let fullName: String?
    var createdAt: Date
    
    init(id: String, email: String? = nil, fullName: String? = nil) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.createdAt = Date()
    }
}

