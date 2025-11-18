//
//  StorageViewModel.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation
import SwiftUI

@MainActor
class StorageViewModel: ObservableObject {
    @Published var creations: [Creation] = []
    @Published var selectedType: CreationType? = nil
    
    let storageService: StorageService
    let userId: String
    
    init(storageService: StorageService, userId: String) {
        self.storageService = storageService
        self.userId = userId
        loadCreations()
    }
    
    func loadCreations() {
        creations = storageService.loadCreations(for: userId)
    }
    
    func saveCreation(_ creation: Creation) {
        storageService.saveCreation(creation)
        loadCreations()
    }
    
    func deleteCreation(_ creation: Creation) {
        storageService.deleteCreation(creation)
        loadCreations()
    }
    
    var filteredCreations: [Creation] {
        if let selectedType = selectedType {
            return creations.filter { $0.type == selectedType }
        }
        return creations
    }
}

