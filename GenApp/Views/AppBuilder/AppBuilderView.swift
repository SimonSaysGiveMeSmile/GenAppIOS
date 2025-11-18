//
//  AppBuilderView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI
import WebKit

struct AppBuilderView: View {
    @ObservedObject var viewModel: AppBuilderViewModel
    @ObservedObject var theme: AppTheme
    @ObservedObject var orchestrator: AppBuilderOrchestrator
    @State private var showPreview = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Component Palette
                ComponentPaletteView(viewModel: viewModel, theme: theme)
                    .frame(width: 200)
                
                Divider()
                
                // Canvas Area
                CanvasView(viewModel: viewModel, theme: theme)
                    .frame(maxWidth: .infinity)
                
                // Properties Panel
                if viewModel.showPropertiesPanel {
                    Divider()
                    PropertiesPanelView(
                        component: viewModel.selectedComponent,
                        viewModel: viewModel,
                        theme: theme
                    )
                    .frame(width: 300)
                }
            }
        }
        .navigationTitle("App Builder")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    orchestrator.validateDesign(viewModel.currentDesign)
                }) {
                    Label("Validate", systemImage: "checkmark.circle")
                }
                
                Button(action: {
                    Task {
                        await viewModel.buildAndRun()
                        showPreview = true
                    }
                }) {
                    Label("Run", systemImage: "play.circle.fill")
                }
                .disabled(viewModel.isRunning)
                
                Button(action: {
                    viewModel.saveApp()
                }) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
            }
        }
        .sheet(isPresented: $showPreview) {
            if let app = orchestrator.generatedApp {
                AppPreviewView(app: app, runtimeService: orchestrator.runtimeService, theme: theme)
            }
        }
    }
}

// MARK: - Component Palette
struct ComponentPaletteView: View {
    @ObservedObject var viewModel: AppBuilderViewModel
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Components")
                    .font(.headline)
                    .padding()
                    .foregroundColor(theme.textColor)
                
                ForEach(ComponentType.allCases, id: \.self) { type in
                    ComponentPaletteItem(
                        type: type,
                        theme: theme
                    ) {
                        let component = createComponent(type: type)
                        viewModel.addComponent(component, to: nil)
                    }
                }
            }
            .padding()
        }
        .background(theme.secondaryBackground)
    }
    
    private func createComponent(type: ComponentType) -> AppComponent {
        let defaultLayout = LayoutProperties(width: 200, height: 100)
        let defaultStyle = StyleProperties()
        var defaultData = ComponentData()
        
        switch type {
        case .text:
            defaultData.text = "Text"
        case .button:
            defaultData.text = "Button"
            defaultData.action = "handleClick"
        case .image:
            defaultData.imageURL = "https://via.placeholder.com/200x100"
        case .input:
            defaultData.placeholder = "Enter text..."
        case .list:
            defaultData.items = ["Item 1", "Item 2", "Item 3"]
        default:
            break
        }
        
        return AppComponent(
            type: type,
            layout: defaultLayout,
            style: defaultStyle,
            data: defaultData
        )
    }
}

struct ComponentPaletteItem: View {
    let type: ComponentType
    @ObservedObject var theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconForType(type))
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 24)
                Text(type.rawValue)
                    .foregroundColor(theme.textColor)
                Spacer()
            }
            .padding()
            .background(theme.backgroundColor)
            .cornerRadius(8)
        }
    }
    
    private func iconForType(_ type: ComponentType) -> String {
        switch type {
        case .container: return "square.stack"
        case .text: return "text.alignleft"
        case .button: return "button.programmable"
        case .image: return "photo"
        case .input: return "textfield"
        case .list: return "list.bullet"
        case .card: return "rectangle.stack"
        case .divider: return "minus"
        case .spacer: return "space"
        }
    }
}

// MARK: - Canvas View
struct CanvasView: View {
    @ObservedObject var viewModel: AppBuilderViewModel
    @ObservedObject var theme: AppTheme
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            // Grid background
            GridBackgroundView(theme: theme)
            
            // Component tree
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ComponentCanvasItem(
                        component: viewModel.currentDesign.rootComponent,
                        viewModel: viewModel,
                        theme: theme,
                        level: 0
                    )
                }
                .padding()
            }
        }
    }
}

struct ComponentCanvasItem: View {
    let component: AppComponent
    @ObservedObject var viewModel: AppBuilderViewModel
    @ObservedObject var theme: AppTheme
    let level: Int
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Component representation
            componentView
                .frame(
                    width: component.layout.width,
                    height: component.type == .spacer ? 20 : component.layout.height
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            viewModel.selectedComponent?.id == component.id
                                ? theme.primaryColor
                                : (isHovered ? theme.primaryColor.opacity(0.5) : Color.clear),
                            lineWidth: 2
                        )
                )
                .onTapGesture {
                    viewModel.selectComponent(component)
                }
                .onHover { hovering in
                    isHovered = hovering
                }
            
            // Children
            if !component.children.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(component.children) { child in
                        ComponentCanvasItem(
                            component: child,
                            viewModel: viewModel,
                            theme: theme,
                            level: level + 1
                        )
                        .padding(.leading, 20)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var componentView: some View {
        switch component.type {
        case .container:
            ZStack {
                Color(hex: component.style.backgroundColor)
                if component.children.isEmpty {
                    Text("Container")
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
        case .text:
            Text(component.data.text ?? "Text")
                .foregroundColor(Color(hex: component.style.textColor))
                .font(.system(size: component.style.fontSize))
            
        case .button:
            Button(action: {}) {
                Text(component.data.text ?? "Button")
                    .foregroundColor(Color(hex: component.style.textColor))
            }
            .buttonStyle(.bordered)
            .background(Color(hex: component.style.backgroundColor))
            
        case .image:
            AsyncImage(url: URL(string: component.data.imageURL ?? "")) { image in
                image.resizable()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            
        case .input:
            TextField(
                component.data.placeholder ?? "",
                text: .constant(component.data.value ?? "")
            )
            .textFieldStyle(.roundedBorder)
            
        case .list:
            VStack(alignment: .leading) {
                ForEach(component.data.items ?? [], id: \.self) { item in
                    Text("• \(item)")
                        .foregroundColor(Color(hex: component.style.textColor))
                }
            }
            
        case .card:
            VStack(alignment: .leading) {
                if let title = component.data.text {
                    Text(title)
                        .font(.headline)
                }
                ForEach(component.children) { child in
                    ComponentCanvasItem(
                        component: child,
                        viewModel: viewModel,
                        theme: theme,
                        level: level + 1
                    )
                }
            }
            .padding()
            .background(Color(hex: component.style.backgroundColor))
            .cornerRadius(component.style.borderRadius)
            
        case .divider:
            Divider()
            
        case .spacer:
            Spacer()
                .frame(height: 20)
        }
    }
}

// MARK: - Properties Panel
struct PropertiesPanelView: View {
    let component: AppComponent?
    @ObservedObject var viewModel: AppBuilderViewModel
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let component = component {
                    Text("Properties")
                        .font(.headline)
                        .padding()
                    
                    // Layout Properties
                    SectionView(title: "Layout") {
                        PropertyRow(label: "X", value: Binding(
                            get: { 
                                guard let comp = viewModel.selectedComponent else { return "0" }
                                return String(comp.layout.x)
                            },
                            set: { 
                                guard var comp = viewModel.selectedComponent else { return }
                                comp.layout.x = Double($0) ?? 0
                                viewModel.updateComponent(comp)
                            }
                        ))
                        PropertyRow(label: "Y", value: Binding(
                            get: { 
                                guard let comp = viewModel.selectedComponent else { return "0" }
                                return String(comp.layout.y)
                            },
                            set: { 
                                guard var comp = viewModel.selectedComponent else { return }
                                comp.layout.y = Double($0) ?? 0
                                viewModel.updateComponent(comp)
                            }
                        ))
                        PropertyRow(label: "Width", value: Binding(
                            get: { 
                                guard let comp = viewModel.selectedComponent else { return "200" }
                                return String(comp.layout.width)
                            },
                            set: { 
                                guard var comp = viewModel.selectedComponent else { return }
                                comp.layout.width = Double($0) ?? 200
                                viewModel.updateComponent(comp)
                            }
                        ))
                        PropertyRow(label: "Height", value: Binding(
                            get: { 
                                guard let comp = viewModel.selectedComponent else { return "100" }
                                return String(comp.layout.height)
                            },
                            set: { 
                                guard var comp = viewModel.selectedComponent else { return }
                                comp.layout.height = Double($0) ?? 100
                                viewModel.updateComponent(comp)
                            }
                        ))
                    }
                    
                    // Style Properties
                    SectionView(title: "Style") {
                        PropertyRow(label: "Background", value: Binding(
                            get: { 
                                guard let comp = viewModel.selectedComponent else { return "#FFFFFF" }
                                return comp.style.backgroundColor
                            },
                            set: { 
                                guard var comp = viewModel.selectedComponent else { return }
                                comp.style.backgroundColor = $0
                                viewModel.updateComponent(comp)
                            }
                        ))
                        PropertyRow(label: "Text Color", value: Binding(
                            get: { 
                                guard let comp = viewModel.selectedComponent else { return "#000000" }
                                return comp.style.textColor
                            },
                            set: { 
                                guard var comp = viewModel.selectedComponent else { return }
                                comp.style.textColor = $0
                                viewModel.updateComponent(comp)
                            }
                        ))
                        PropertyRow(label: "Font Size", value: Binding(
                            get: { 
                                guard let comp = viewModel.selectedComponent else { return "16" }
                                return String(comp.style.fontSize)
                            },
                            set: { 
                                guard var comp = viewModel.selectedComponent else { return }
                                comp.style.fontSize = Double($0) ?? 16
                                viewModel.updateComponent(comp)
                            }
                        ))
                        PropertyRow(label: "Border Radius", value: Binding(
                            get: { 
                                guard let comp = viewModel.selectedComponent else { return "0" }
                                return String(comp.style.borderRadius)
                            },
                            set: { 
                                guard var comp = viewModel.selectedComponent else { return }
                                comp.style.borderRadius = Double($0) ?? 0
                                viewModel.updateComponent(comp)
                            }
                        ))
                    }
                    
                    // Data Properties (type-specific)
                    if component.type == .text || component.type == .button {
                        SectionView(title: "Content") {
                            PropertyRow(label: "Text", value: Binding(
                                get: { 
                                    guard let comp = viewModel.selectedComponent else { return "" }
                                    return comp.data.text ?? ""
                                },
                                set: { 
                                    guard var comp = viewModel.selectedComponent else { return }
                                    comp.data.text = $0.isEmpty ? nil : $0
                                    viewModel.updateComponent(comp)
                                }
                            ))
                        }
                    }
                } else {
                    Text("No component selected")
                        .foregroundColor(theme.secondaryTextColor)
                        .padding()
                }
            }
            .padding()
        }
        .background(theme.secondaryBackground)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            content
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PropertyRow: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 100, alignment: .leading)
            TextField("", text: $value)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - App Preview
struct AppPreviewView: View {
    let app: GeneratedApp
    let runtimeService: AppRuntimeService
    @ObservedObject var theme: AppTheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                AppRuntimeView(runtimeService: runtimeService, app: app)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .navigationTitle(app.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            runtimeService.runApp(app)
        }
    }
}

struct AppRuntimeView: UIViewRepresentable {
    let runtimeService: AppRuntimeService
    let app: GeneratedApp
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = runtimeService.createWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        runtimeService.runApp(app)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // View updates handled by runtime service
    }
}

struct GridBackgroundView: View {
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 20
                for x in stride(from: 0, through: geometry.size.width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                for y in stride(from: 0, through: geometry.size.height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(theme.secondaryTextColor.opacity(0.1), lineWidth: 1)
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
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

