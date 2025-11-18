//
//  MainTabView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var theme: AppTheme
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var storageViewModel: StorageViewModel
    @StateObject private var marketplaceViewModel: MarketplaceViewModel
    @StateObject private var appBuilderOrchestrator: AppBuilderOrchestrator
    
    init(authService: AuthenticationService, theme: AppTheme) {
        self.authService = authService
        self.theme = theme
        
        let openAIService = OpenAIService()
        let runtimeService = AppRuntimeService()
        let orchestrator = AppBuilderOrchestrator(
            runtimeService: runtimeService
        )
        _appBuilderOrchestrator = StateObject(wrappedValue: orchestrator)
        
        let storageService = StorageService()
        let userId = authService.currentUser?.id ?? "default_user"
        _storageViewModel = StateObject(wrappedValue: StorageViewModel(storageService: storageService, userId: userId))
        
        // Create chat view model with orchestrator and storage service
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(
            openAIService: openAIService,
            appBuilderOrchestrator: orchestrator,
            storageService: storageService,
            userId: userId
        ))
        
        let marketplaceService = MarketplaceService()
        _marketplaceViewModel = StateObject(wrappedValue: MarketplaceViewModel(marketplaceService: marketplaceService))
    }
    
    var body: some View {
        TabView {
            ChatView(viewModel: chatViewModel, theme: theme)
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
            
            StorageView(viewModel: storageViewModel, theme: theme)
                .tabItem {
                    Label("Storage", systemImage: "tray.fill")
                }
            
            MarketplaceView(viewModel: marketplaceViewModel, theme: theme)
                .tabItem {
                    Label("Marketplace", systemImage: "storefront.fill")
                }
            
            SettingsView(authService: authService, theme: theme)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(theme.primaryColor)
    }
}

