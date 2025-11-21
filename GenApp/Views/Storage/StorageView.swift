//
//  StorageView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI

struct StorageView: View {
    @ObservedObject var viewModel: StorageViewModel
    @ObservedObject var theme: AppTheme
    @State private var showCreateSheet = false
    @State private var showAppBuilder = false
    @State private var showAppPreview = false
    @State private var previewApp: MiniAppSpec?
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(
                                title: "All",
                                isSelected: viewModel.selectedType == nil,
                                theme: theme
                            ) {
                                viewModel.selectedType = nil
                            }
                            
                            ForEach([CreationType.app, .illustration, .answer, .reference], id: \.self) { type in
                                FilterButton(
                                    title: type.rawValue.capitalized,
                                    isSelected: viewModel.selectedType == type,
                                    theme: theme
                                ) {
                                    viewModel.selectedType = type
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(theme.secondaryBackground)
                    
                    // Creations grid
                    if viewModel.filteredCreations.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "tray")
                                .font(.system(size: 60))
                                .foregroundColor(theme.secondaryTextColor)
                            Text("No creations yet")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(theme.textColor)
                            Text("Create something amazing!")
                                .font(.system(size: 16))
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(viewModel.filteredCreations) { creation in
                                    CreationCard(creation: creation, theme: theme)
                                        .onTapGesture {
                                            if creation.type == .app {
                                                // Open app preview
                                                openAppPreview(creation: creation)
                                            }
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("My Creations")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: {
                        showAppBuilder = true
                    }) {
                        Label("App Builder", systemImage: "app.badge")
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    Button(action: {
                        showCreateSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateCreationView(viewModel: viewModel, theme: theme)
            }
            .sheet(isPresented: $showAppBuilder) {
                AppBuilderSheetView(viewModel: viewModel, theme: theme)
            }
            .sheet(isPresented: $showAppPreview) {
                if let spec = previewApp {
                    AppPreviewView(spec: spec, runtimeService: AppRuntimeService(), theme: theme)
                }
            }
            .onAppear {
                viewModel.loadCreations()
            }
        }
    }
    
    private func openAppPreview(creation: Creation) {
        guard let spec = decodeMiniApp(from: creation.content, fallbackTitle: creation.title, id: creation.id) else {
            return
        }
        
        previewApp = spec
        showAppPreview = true
    }
    
    private func decodeMiniApp(from content: String, fallbackTitle: String, id: String) -> MiniAppSpec? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let directData = content.data(using: .utf8),
           let spec = try? decoder.decode(MiniAppSpec.self, from: directData) {
            return spec
        }
        
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        if let miniAppJson = json["miniAppJson"] as? String,
           let miniAppData = miniAppJson.data(using: .utf8),
           let spec = try? decoder.decode(MiniAppSpec.self, from: miniAppData) {
            return spec
        }
        
        // Legacy HTML payloads are no longer supported; wrap them in a placeholder MiniApp
        if let html = json["html"] as? String {
            let page = MiniAppPage(
                id: "legacy-\(id)",
                title: fallbackTitle,
                layout: .scroll,
                components: [
                    MiniAppComponent(
                        id: UUID().uuidString,
                        type: .label,
                        props: MiniAppComponentProps(
                            text: "Legacy app preview is no longer supported. Regenerate this idea via Chat.",
                            style: .defaultStyle
                        ),
                        bindings: nil,
                        actionIds: [],
                        children: []
                    )
                ]
            )
            return MiniAppSpec(
                id: id,
                ownerId: "legacy",
                name: fallbackTitle,
                description: "Legacy HTML artifact length \(html.count)",
                pages: [page],
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        return nil
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    @ObservedObject var theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                gradient: Gradient(colors: [theme.primaryColor, theme.primaryColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            theme.secondaryBackground
                        }
                    }
                )
                .cornerRadius(20)
        }
    }
}

struct CreationCard: View {
    let creation: Creation
    @ObservedObject var theme: AppTheme
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            theme.primaryColor.opacity(0.3),
                            theme.primaryColor.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    Image(systemName: iconForType(creation.type))
                        .font(.system(size: 40))
                        .foregroundColor(theme.primaryColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(creation.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                    .lineLimit(1)
                
                Text(creation.description)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryTextColor)
                    .lineLimit(2)
                
                Text(creation.type.rawValue.capitalized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.primaryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.primaryColor.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(theme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private func iconForType(_ type: CreationType) -> String {
        switch type {
        case .app: return "app.badge"
        case .illustration: return "paintbrush.fill"
        case .answer: return "doc.text.fill"
        case .reference: return "book.fill"
        }
    }
}

struct CreateCreationView: View {
    @ObservedObject var viewModel: StorageViewModel
    @ObservedObject var theme: AppTheme
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var content = ""
    @State private var selectedType: CreationType = .app
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach([CreationType.app, .illustration, .answer, .reference], id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("New Creation")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let creation = Creation(
                            userId: viewModel.userId,
                            title: title,
                            description: description,
                            type: selectedType,
                            content: content
                        )
                        viewModel.saveCreation(creation)
                        dismiss()
                    }
                    .disabled(title.isEmpty || description.isEmpty)
                }
            }
        }
    }
}

