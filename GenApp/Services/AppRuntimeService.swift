//
//  AppRuntimeService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//  Refactored for MiniApp DSL runtime on 11/19/25.
//

import Foundation

/// Hosts SwiftUI-first MiniApps generated from the DSL.
/// This service manages the live execution environment for generated apps.
final class AppRuntimeService: ObservableObject {
    @Published private(set) var runtime: MiniAppRuntime?
    
    /// Loads a MiniApp spec into the runtime for live execution.
    /// The app will be immediately available for rendering and interaction.
    func load(spec: MiniAppSpec) {
        // Create runtime instance - this initializes the app's state and makes it ready for execution
        runtime = MiniAppRuntime(spec: spec)
    }
    
    /// Resets the runtime, stopping the current app.
    func reset() {
        runtime = nil
    }
    
    /// Stops the currently running app.
    func stopApp() {
        reset()
    }
    
    /// Returns true if an app is currently loaded and running.
    var isRunning: Bool {
        runtime != nil
    }
}

