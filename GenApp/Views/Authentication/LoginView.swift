//
//  LoginView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.9, green: 0.95, blue: 1.0),
                    theme.isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.25) : Color(red: 0.95, green: 0.98, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.primaryColor, theme.primaryColor.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: theme.primaryColor.opacity(0.5), radius: 20)
                    
                    Text("GenApp")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("Create, Share, Discover")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(.bottom, 40)
                
                // Sign in button
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(_):
                        // Handle successful authorization
                        authService.signInWithApple()
                    case .failure(let error):
                        // Handle error
                        print("Sign in with Apple failed: \(error.localizedDescription)")
                    }
                }
                .signInWithAppleButtonStyle(theme.isDarkMode ? .white : .black)
                .frame(height: 55)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}

