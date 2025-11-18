//
//  MarketplaceService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

class MarketplaceService {
    private let userDefaults = UserDefaults.standard
    private let itemsKey = "marketplaceItems"
    private let reviewsKey = "marketplaceReviews"
    
    // Mock data for demonstration
    func loadMarketplaceItems() -> [MarketplaceItem] {
        // In production, this would fetch from a backend
        // For now, return mock data or saved items
        if let data = userDefaults.data(forKey: itemsKey),
           let items = try? JSONDecoder().decode([MarketplaceItem].self, from: data),
           !items.isEmpty {
            return items
        }
        
        // Return sample items
        return generateSampleItems()
    }
    
    func loadReviews(for itemId: String) -> [Review] {
        guard let data = userDefaults.data(forKey: reviewsKey),
              let allReviews = try? JSONDecoder().decode([Review].self, from: data) else {
            return []
        }
        return allReviews.filter { $0.itemId == itemId }
    }
    
    func addReview(_ review: Review) {
        var reviews = loadAllReviews()
        reviews.append(review)
        saveReviews(reviews)
        updateItemRating(itemId: review.itemId)
    }
    
    func downloadItem(_ item: MarketplaceItem) {
        // In production, this would download from a server
        // For now, just increment download count
        var items = loadMarketplaceItems()
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let updatedItem = items[index]
            // Note: MarketplaceItem is a struct, so we need to recreate it
            let newItem = MarketplaceItem(
                id: updatedItem.id,
                creationId: updatedItem.creationId,
                creatorId: updatedItem.creatorId,
                creatorName: updatedItem.creatorName,
                title: updatedItem.title,
                description: updatedItem.description,
                price: updatedItem.price,
                isFree: updatedItem.isFree,
                hasTrial: updatedItem.hasTrial,
                rating: updatedItem.rating,
                reviewCount: updatedItem.reviewCount,
                downloadCount: updatedItem.downloadCount + 1,
                thumbnailURL: updatedItem.thumbnailURL,
                category: updatedItem.category
            )
            items[index] = newItem
            saveItems(items)
        }
    }
    
    func publishCreation(_ creation: Creation, as item: MarketplaceItem) {
        var items = loadMarketplaceItems()
        items.append(item)
        saveItems(items)
    }
    
    private func loadAllReviews() -> [Review] {
        guard let data = userDefaults.data(forKey: reviewsKey),
              let reviews = try? JSONDecoder().decode([Review].self, from: data) else {
            return []
        }
        return reviews
    }
    
    private func saveReviews(_ reviews: [Review]) {
        if let data = try? JSONEncoder().encode(reviews) {
            userDefaults.set(data, forKey: reviewsKey)
        }
    }
    
    private func saveItems(_ items: [MarketplaceItem]) {
        if let data = try? JSONEncoder().encode(items) {
            userDefaults.set(data, forKey: itemsKey)
        }
    }
    
    private func updateItemRating(itemId: String) {
        let reviews = loadReviews(for: itemId)
        let averageRating = reviews.isEmpty ? 0.0 : Double(reviews.map { $0.rating }.reduce(0, +)) / Double(reviews.count)
        
        var items = loadMarketplaceItems()
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            let item = items[index]
            let newItem = MarketplaceItem(
                id: item.id,
                creationId: item.creationId,
                creatorId: item.creatorId,
                creatorName: item.creatorName,
                title: item.title,
                description: item.description,
                price: item.price,
                isFree: item.isFree,
                hasTrial: item.hasTrial,
                rating: averageRating,
                reviewCount: reviews.count,
                downloadCount: item.downloadCount,
                thumbnailURL: item.thumbnailURL,
                category: item.category
            )
            items[index] = newItem
            saveItems(items)
        }
    }
    
    private func generateSampleItems() -> [MarketplaceItem] {
        return [
            MarketplaceItem(
                creationId: UUID().uuidString,
                creatorId: "sample1",
                creatorName: "Design Pro",
                title: "Modern UI Components",
                description: "A collection of beautiful, modern UI components for iOS apps",
                price: 9.99,
                isFree: false,
                hasTrial: true,
                rating: 4.5,
                reviewCount: 23,
                downloadCount: 150,
                category: "Apps"
            ),
            MarketplaceItem(
                creationId: UUID().uuidString,
                creatorId: "sample2",
                creatorName: "Art Studio",
                title: "Abstract Art Collection",
                description: "Stunning abstract illustrations perfect for any project",
                price: 0,
                isFree: true,
                hasTrial: false,
                rating: 4.8,
                reviewCount: 45,
                downloadCount: 320,
                category: "Illustrations"
            ),
            MarketplaceItem(
                creationId: UUID().uuidString,
                creatorId: "sample3",
                creatorName: "Code Master",
                title: "SwiftUI Templates",
                description: "Production-ready SwiftUI templates and patterns",
                price: 14.99,
                isFree: false,
                hasTrial: true,
                rating: 4.7,
                reviewCount: 67,
                downloadCount: 280,
                category: "Apps"
            )
        ]
    }
}

