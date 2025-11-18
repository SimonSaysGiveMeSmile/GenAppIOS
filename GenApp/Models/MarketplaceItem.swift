//
//  MarketplaceItem.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

struct MarketplaceItem: Identifiable, Codable {
    let id: String
    let creationId: String
    let creatorId: String
    let creatorName: String
    let title: String
    let description: String
    let price: Double
    let isFree: Bool
    let hasTrial: Bool
    let rating: Double
    let reviewCount: Int
    let downloadCount: Int
    let thumbnailURL: String?
    let category: String
    var createdAt: Date
    
    init(id: String = UUID().uuidString, creationId: String, creatorId: String, creatorName: String, title: String, description: String, price: Double = 0, isFree: Bool = true, hasTrial: Bool = false, rating: Double = 0, reviewCount: Int = 0, downloadCount: Int = 0, thumbnailURL: String? = nil, category: String = "General") {
        self.id = id
        self.creationId = creationId
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.title = title
        self.description = description
        self.price = price
        self.isFree = isFree
        self.hasTrial = hasTrial
        self.rating = rating
        self.reviewCount = reviewCount
        self.downloadCount = downloadCount
        self.thumbnailURL = thumbnailURL
        self.category = category
        self.createdAt = Date()
    }
}

struct Review: Identifiable, Codable {
    let id: String
    let itemId: String
    let userId: String
    let userName: String
    let rating: Int
    let comment: String
    var createdAt: Date
    
    init(id: String = UUID().uuidString, itemId: String, userId: String, userName: String, rating: Int, comment: String) {
        self.id = id
        self.itemId = itemId
        self.userId = userId
        self.userName = userName
        self.rating = rating
        self.comment = comment
        self.createdAt = Date()
    }
}

