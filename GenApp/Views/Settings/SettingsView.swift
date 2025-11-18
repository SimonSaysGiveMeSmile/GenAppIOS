//
//  SettingsView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var theme: AppTheme
    @State private var apiKey: String = ""
    @State private var showAPIKeyAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(authService.currentUser?.fullName ?? "User")
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    
                    if let email = authService.currentUser?.email {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                }
                
                Section("OpenAI API") {
                    HStack {
                        Text("API Key")
                        Spacer()
                        SecureField("Enter API Key", text: $apiKey)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(theme.textColor)
                    }
                    
                    Button(action: {
                        // Save API key (in production, use Keychain)
                        UserDefaults.standard.set(apiKey, forKey: "openai_api_key")
                        showAPIKeyAlert = true
                    }) {
                        Text("Save API Key")
                            .foregroundColor(theme.primaryColor)
                    }
                }
                
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: Binding(
                        get: { theme.isDarkMode },
                        set: { _ in theme.toggleColorScheme() }
                    ))
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
            }
            .alert("API Key Saved", isPresented: $showAPIKeyAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your OpenAI API key has been saved. Restart the app for changes to take effect.")
            }
        }
    }
}

