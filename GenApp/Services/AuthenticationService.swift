//
//  AuthenticationService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation
import SwiftUI

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    
    init() {
        // Start with no user (will be set after sign-in)
        self.currentUser = nil
    }
    
    func signInWithApple() {
        // TODO: Implement actual Sign in with Apple authentication
        // For now, create a default user for testing
        self.currentUser = User(
            id: UUID().uuidString,
            email: "user@example.com",
            fullName: "User"
        )
    }
}

