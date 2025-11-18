//
//  AppRuntimeService.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import Foundation
import WebKit
import SwiftUI

class AppRuntimeService: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var runtimeError: String?
    
    private var webView: WKWebView?
    
    func createWebView(frame: CGRect) -> WKWebView {
        let config = WKWebViewConfiguration()
        if #available(iOS 14.0, *) {
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = true
            config.defaultWebpagePreferences = preferences
        } else {
            config.preferences.javaScriptEnabled = true
        }
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Allow inline media playback
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: frame, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        self.webView = webView
        
        return webView
    }
    
    func runApp(_ app: GeneratedApp) {
        guard let webView = webView else { return }
        
        isRunning = true
        runtimeError = nil
        
        // Combine HTML, CSS, and JS into a single HTML document
        let fullHTML = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <title>\(app.name)</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    overflow-x: hidden;
                }
                \(app.css)
            </style>
        </head>
        <body>
            \(app.html.replacingOccurrences(of: "<!DOCTYPE html>", with: "").replacingOccurrences(of: "<html lang=\"en\">", with: "").replacingOccurrences(of: "<head>.*</head>", with: "", options: .regularExpression).replacingOccurrences(of: "<link.*>", with: "", options: .regularExpression).replacingOccurrences(of: "<script src=\"app-script.js\"></script>", with: ""))
            <script>
                \(app.javascript)
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(fullHTML, baseURL: nil)
    }
    
    func stopApp() {
        webView?.stopLoading()
        isRunning = false
    }
    
    func reloadApp(_ app: GeneratedApp) {
        stopApp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.runApp(app)
        }
    }
}

// MARK: - WKNavigationDelegate
extension AppRuntimeService: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isRunning = true
        runtimeError = nil
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        runtimeError = error.localizedDescription
        isRunning = false
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        runtimeError = error.localizedDescription
        isRunning = false
    }
}

// MARK: - WKUIDelegate
extension AppRuntimeService: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        // Handle JavaScript alerts if needed
        completionHandler()
    }
}

