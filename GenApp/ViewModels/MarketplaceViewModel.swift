//
//  MarketplaceViewModel.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation
import SwiftUI

@MainActor
class MarketplaceViewModel: ObservableObject {
    @Published var items: [MarketplaceItem] = []
    @Published var selectedItem: MarketplaceItem?
    @Published var reviews: [Review] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    
    private let marketplaceService: MarketplaceService
    
    init(marketplaceService: MarketplaceService) {
        self.marketplaceService = marketplaceService
        loadItems()
    }
    
    func loadItems() {
        items = marketplaceService.loadMarketplaceItems()
    }
    
    func loadReviews(for itemId: String) {
        reviews = marketplaceService.loadReviews(for: itemId)
    }
    
    func addReview(_ review: Review) {
        marketplaceService.addReview(review)
        loadReviews(for: review.itemId)
        loadItems() // Refresh to update ratings
    }
    
    func downloadItem(_ item: MarketplaceItem) {
        marketplaceService.downloadItem(item)
        loadItems()
    }
    
    var filteredItems: [MarketplaceItem] {
        var filtered = items
        
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        return filtered
    }
    
    var categories: [String] {
        var cats = Set(items.map { $0.category })
        cats.insert("All")
        return Array(cats).sorted()
    }
}

