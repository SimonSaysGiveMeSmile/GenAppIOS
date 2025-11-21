//
//  ChatView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message, theme: theme)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading && !viewModel.isBuildingApp {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primaryColor))
                                    Text("Thinking...")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.secondaryTextColor)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if viewModel.isBuildingApp {
                                BuildProgressView(
                                    theme: theme,
                                    progress: viewModel.buildProgress,
                                    status: viewModel.buildStatusMessage.isEmpty ? 
                                        statusForProgress(progress: viewModel.buildProgress) : 
                                        viewModel.buildStatusMessage
                                )
                                .padding(.vertical)
                                
                                if !viewModel.toolCallHistory.isEmpty {
                                    ToolCallStackView(theme: theme, toolCalls: viewModel.toolCallHistory)
                                        .padding(.bottom, 8)
                                }
                            } else if viewModel.generatedMiniApp != nil {
                                PreviewCTAView(
                                    theme: theme,
                                    appName: viewModel.generatedAppDesign?.name ?? "Generated App",
                                    status: "Local runtime ready for preview",
                                    onPreview: {
                                        viewModel.openPreview()
                                    }
                                )
                                .padding(.bottom, 16)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { oldValue, newValue in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input area
                VStack(spacing: 0) {
                    Divider()
                        .background(theme.secondaryTextColor.opacity(0.3))
                    
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $viewModel.inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(theme.secondaryBackground)
                            .cornerRadius(25)
                            .foregroundColor(theme.textColor)
                            .lineLimit(1...5)
                            .onSubmit {
                                viewModel.sendMessage()
                            }
                        
                        Button(action: {
                            viewModel.sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(viewModel.inputText.isEmpty ? theme.secondaryTextColor : theme.primaryColor)
                        }
                        .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                    }
                    .padding()
                    .background(theme.backgroundColor)
                }
            }
        }
        .overlay {
            if viewModel.showSavePrompt {
                if let design = viewModel.generatedAppDesign {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                viewModel.dismissSavePrompt()
                            }
                        
                        SaveAppPromptView(
                            theme: theme,
                            appName: design.name,
                            onSave: {
                                viewModel.saveGeneratedApp()
                            },
                            onDismiss: {
                                viewModel.dismissSavePrompt()
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showAppPreview, onDismiss: {
            viewModel.dismissPreview()
        }) {
            if let spec = viewModel.generatedMiniApp {
                AppPreviewView(spec: spec, runtimeService: viewModel.runtimeService, theme: theme)
            }
        }
        .navigationTitle("Chat")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.clearChat()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(theme.primaryColor)
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.clearChat()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(theme.primaryColor)
                }
            }
            #endif
        }
    }
    
    private func statusForProgress(progress: Double) -> String {
        if progress < 0.3 {
            return "Analyzing requirements..."
        } else if progress < 0.5 {
            return "Designing app structure..."
        } else if progress < 0.7 {
            return "Generating code..."
        } else if progress < 0.9 {
            return "Validating & debugging..."
        } else {
            return "Finalizing..."
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @ObservedObject var theme: AppTheme
    @State private var appear = false
    
    var isUser: Bool {
        message.role == .user
    }
    
    var isLog: Bool {
        message.role == .log
    }
    
    var body: some View {
        Group {
            if isLog {
                logBubble
            } else {
                standardBubble
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
    
    private var standardBubble: some View {
        HStack {
            if isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(isUser ? .white : theme.textColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if isUser {
                                LinearGradient(
                                    gradient: Gradient(colors: [theme.primaryColor, theme.primaryColor.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                theme.secondaryBackground
                            }
                        }
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .scaleEffect(appear ? 1 : 0.8)
                    .opacity(appear ? 1 : 0)
            }
            
            if !isUser {
                Spacer(minLength: 50)
            }
        }
    }
    
    private var logBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.secondaryTextColor)
            
            Text(message.content)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            theme.secondaryBackground
                .opacity(theme.isDarkMode ? 0.4 : 0.8)
        )
        .cornerRadius(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scaleEffect(appear ? 1 : 0.95)
        .opacity(appear ? 1 : 0)
    }
}

struct PreviewCTAView: View {
    @ObservedObject var theme: AppTheme
    let appName: String
    let status: String
    let onPreview: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(appName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textColor)
                Spacer()
                Label("Runtime Ready", systemImage: "bolt.horizontal.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.primaryColor)
            }
            
            Text(status)
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
            
            Button(action: onPreview) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Open Live Preview")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [theme.primaryColor, theme.primaryColor.opacity(0.85)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.secondaryBackground)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}