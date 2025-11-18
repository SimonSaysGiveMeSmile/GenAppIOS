//
//  StorageService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation

class StorageService {
    private let userDefaults = UserDefaults.standard
    private let creationsKey = "userCreations"
    
    func saveCreation(_ creation: Creation) {
        var creations = loadCreations()
        if let index = creations.firstIndex(where: { $0.id == creation.id }) {
            creations[index] = creation
        } else {
            creations.append(creation)
        }
        saveCreations(creations)
    }
    
    func loadCreations() -> [Creation] {
        guard let data = userDefaults.data(forKey: creationsKey),
              let creations = try? JSONDecoder().decode([Creation].self, from: data) else {
            return []
        }
        return creations
    }
    
    func loadCreations(for userId: String) -> [Creation] {
        return loadCreations().filter { $0.userId == userId }
    }
    
    func deleteCreation(_ creation: Creation) {
        var creations = loadCreations()
        creations.removeAll { $0.id == creation.id }
        saveCreations(creations)
    }
    
    private func saveCreations(_ creations: [Creation]) {
        if let data = try? JSONEncoder().encode(creations) {
            userDefaults.set(data, forKey: creationsKey)
        }
    }
}

