//
//  ContentView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var theme = AppTheme()
    
    var body: some View {
        // For testing: Always show main app (mock user is auto-created)
        MainTabView(authService: authService, theme: theme)
            .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    ContentView()
}
