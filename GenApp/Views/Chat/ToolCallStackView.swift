//
//  ToolCallStackView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/18/25.
//

import SwiftUI

struct ToolCallStackView: View {
    @ObservedObject var theme: AppTheme
    let toolCalls: [ToolCallSummary]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("OpenAI Tool Calls")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.secondaryTextColor)
                Spacer()
                Text("\(toolCalls.count)x")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.secondaryTextColor.opacity(0.8))
            }
            
            ForEach(toolCalls) { call in
                HStack(spacing: 12) {
                    Image(systemName: call.tool.systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color(for: call.status))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(color(for: call.status).opacity(0.12))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(call.tool.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textColor)
                        
                        Text(description(for: call))
                            .font(.system(size: 13))
                            .foregroundColor(theme.secondaryTextColor)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Text(statusLabel(for: call))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color(for: call.status))
                }
                .padding(12)
                .background(theme.secondaryBackground)
                .cornerRadius(14)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(theme.secondaryBackground.opacity(theme.isDarkMode ? 0.4 : 0.3))
        .cornerRadius(18)
    }
    
    private func color(for status: ToolCallStatus) -> Color {
        switch status {
        case .pending:
            return theme.secondaryTextColor
        case .running:
            return theme.primaryColor
        case .completed:
            return theme.primaryColor
        case .failed:
            return .red
        }
    }
    
    private func statusLabel(for call: ToolCallSummary) -> String {
        switch call.status {
        case .pending:
            return "Pending"
        case .running:
            return "Running"
        case .completed:
            let milliseconds = Int(call.duration * 1000)
            return milliseconds > 0 ? "\(milliseconds)ms" : "Done"
        case .failed:
            return "Failed"
        }
    }
    
    private func description(for call: ToolCallSummary) -> String {
        if !call.outputSummary.isEmpty {
            return call.outputSummary
        }
        return call.inputPreview
    }
}

