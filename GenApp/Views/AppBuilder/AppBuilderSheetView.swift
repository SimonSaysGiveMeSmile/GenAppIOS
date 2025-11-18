//
//  AppBuilderSheetView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI

struct AppBuilderSheetView: View {
    @ObservedObject var viewModel: StorageViewModel
    @ObservedObject var theme: AppTheme
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var orchestrator: AppBuilderOrchestrator
    @StateObject private var builderViewModel: AppBuilderViewModel
    
    init(viewModel: StorageViewModel, theme: AppTheme) {
        self.viewModel = viewModel
        self.theme = theme
        
        let runtimeService = AppRuntimeService()
        let orchestrator = AppBuilderOrchestrator(
            runtimeService: runtimeService
        )
        
        _orchestrator = StateObject(wrappedValue: orchestrator)
        _builderViewModel = StateObject(wrappedValue: AppBuilderViewModel(
            orchestrator: orchestrator,
            storageService: viewModel.storageService,
            userId: viewModel.userId
        ))
    }
    
    var body: some View {
        NavigationView {
            AppBuilderView(
                viewModel: builderViewModel,
                theme: theme,
                orchestrator: orchestrator
            )
        }
    }
}

