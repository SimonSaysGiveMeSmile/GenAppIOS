//
//  BuildProgressView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI

struct BuildProgressView: View {
    @ObservedObject var theme: AppTheme
    let progress: Double
    let status: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Animated icon
            ZStack {
                Circle()
                    .stroke(theme.primaryColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(theme.primaryColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: progress)
                
                Image(systemName: iconForProgress(progress))
                    .font(.system(size: 24))
                    .foregroundColor(theme.primaryColor)
            }
            
            VStack(spacing: 8) {
                Text(status)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(theme.secondaryBackground)
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [theme.primaryColor, theme.primaryColor.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                            .animation(.linear(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Spacer()
                    
                    // Step indicator
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(stepColor(for: index, progress: progress))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(20)
        .background(theme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding()
    }
    
    private func stepColor(for index: Int, progress: Double) -> Color {
        let stepProgress = Double(index) / 4.0
        if progress >= stepProgress {
            return theme.primaryColor
        } else {
            return theme.secondaryTextColor.opacity(0.3)
        }
    }
    
    private func iconForProgress(_ progress: Double) -> String {
        if progress < 0.3 {
            return "wand.and.stars"
        } else if progress < 0.6 {
            return "gearshape.2"
        } else if progress < 0.9 {
            return "checkmark.circle"
        } else {
            return "checkmark.circle.fill"
        }
    }
}

struct SaveAppPromptView: View {
    @ObservedObject var theme: AppTheme
    let appName: String
    let onSave: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 50))
                .foregroundColor(theme.primaryColor)
            
            Text("App Ready!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.textColor)
            
            Text("Your app '\(appName)' has been built successfully. Would you like to save it to 'My Creations' to test it?")
                .font(.system(size: 16))
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button(action: onDismiss) {
                    Text("Not Now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.secondaryBackground)
                        .cornerRadius(12)
                }
                
                Button(action: onSave) {
                    Text("Save & Test")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.primaryColor, theme.primaryColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding(30)
        .background(theme.backgroundColor)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(40)
    }
}

