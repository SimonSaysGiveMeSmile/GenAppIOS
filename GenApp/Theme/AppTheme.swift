//
//  AppTheme.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI

class AppTheme: ObservableObject {
    @Published var colorScheme: ColorScheme = .light
    
    var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    // Color palette
    var primaryColor: Color {
        isDarkMode ? Color(red: 0.2, green: 0.4, blue: 0.9) : Color(red: 0.1, green: 0.3, blue: 0.8)
    }
    
    var backgroundColor: Color {
        isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.15) : Color(red: 0.98, green: 0.98, blue: 1.0)
    }
    
    var secondaryBackground: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white
    }
    
    var textColor: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        isDarkMode ? Color(red: 0.7, green: 0.7, blue: 0.7) : Color(red: 0.4, green: 0.4, blue: 0.4)
    }
    
    func toggleColorScheme() {
        colorScheme = colorScheme == .light ? .dark : .light
    }
}

// Glass morphism modifier
struct GlassMorphism: ViewModifier {
    let theme: AppTheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                theme.isDarkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.7),
                                theme.isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 20)
                    )
            )
            .shadow(color: theme.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassMorphism(theme: AppTheme) -> some View {
        modifier(GlassMorphism(theme: theme))
    }
}

// Frosted glass modifier
struct FrostedGlass: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(20)
    }
}

extension View {
    func frostedGlass() -> some View {
        modifier(FrostedGlass())
    }
}

// MARK: - Shared Color Helpers
extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch sanitized.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

