//
//  MiniAppRenderer.swift
//  GenApp
//
//  Created by GPT-5.1 Codex on 11/19/25.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Observable runtime container that keeps page navigation and state for a MiniApp.
final class MiniAppRuntime: ObservableObject, Identifiable {
    let id = UUID()
    let spec: MiniAppSpec
    
    @Published var currentPageId: String
    @Published var state: [String: MiniAppValue]
    @Published var activeAlert: MiniAppAlert?
    
    private lazy var actionLookup: [String: MiniAppAction] = {
        Dictionary(uniqueKeysWithValues: spec.actions.map { ($0.id, $0) })
    }()
    
    init(spec: MiniAppSpec) {
        self.spec = spec
        self.currentPageId = spec.pages.first?.id ?? "main"
        self.state = spec.initialState
    }
    
    var currentPage: MiniAppPage? {
        spec.pages.first(where: { $0.id == currentPageId })
    }
    
    func binding(for key: String, default defaultValue: MiniAppValue = .string("")) -> Binding<String> {
        Binding<String>(
            get: { self.state[key]?.stringValue ?? defaultValue.stringValue ?? "" },
            set: { self.state[key] = .string($0) }
        )
    }
    
    func toggleBinding(_ key: String) {
        let current = state[key]?.boolValue ?? false
        state[key] = .bool(!current)
    }
    
    func performActions(for component: MiniAppComponent) {
        for actionId in component.actionIds {
            guard let action = actionLookup[actionId] else { continue }
            handle(action)
        }
    }
    
    private func handle(_ action: MiniAppAction) {
        switch action.type {
        case .navigate:
            if let target = action.params["targetPageId"]?.stringValue {
                withAnimation {
                    currentPageId = target
                }
            }
        case .showAlert:
            let title = action.params["title"]?.stringValue ?? spec.name
            let message = action.params["message"]?.stringValue ?? "Action completed."
            activeAlert = MiniAppAlert(title: title, message: message)
        case .setState:
            if let key = action.params["key"]?.stringValue,
               let value = action.params["value"] {
                state[key] = value
            }
        case .toggleFlashlight:
            activeAlert = MiniAppAlert(
                title: "Flashlight",
                message: "Flashlight toggle requested. Hook into device APIs on backend build."
            )
        case .startTimer:
            activeAlert = MiniAppAlert(
                title: "Timer",
                message: "Timer started locally."
            )
        }
    }
}

struct MiniAppRendererView: View {
    @ObservedObject var runtime: MiniAppRuntime
    private let renderer = MiniAppRenderer()
    
    var body: some View {
        VStack(spacing: 0) {
            if let page = runtime.currentPage {
                pageView(page)
            } else {
                Text("Missing page")
                    .foregroundColor(.secondary)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .alert(item: Binding(get: { runtime.activeAlert }, set: { _ in runtime.activeAlert = nil })) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }
    
    private func pageView(_ page: MiniAppPage) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                if let title = page.title {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                
                ForEach(page.components) { component in
                    renderer.view(for: component, runtime: runtime)
                        .padding(.horizontal, component.props.layoutHint == .hero ? 12 : 20)
                }
            }
            .padding(.vertical, 24)
        }
    }
}

/// Responsible for mapping MiniApp components to SwiftUI equivalents.
struct MiniAppRenderer {
    func view(for component: MiniAppComponent, runtime: MiniAppRuntime) -> AnyView {
        switch component.type {
        case .container:
            return AnyView(containerView(component, runtime: runtime))
        case .label:
            return AnyView(label(component))
        case .button:
            return AnyView(button(component, runtime: runtime))
        case .toggle:
            return AnyView(toggle(component, runtime: runtime))
        case .image:
            return AnyView(remoteImage(component))
        case .timerDisplay:
            return AnyView(label(component))
        case .list:
            return AnyView(list(component))
        case .input:
            return AnyView(input(component, runtime: runtime))
        case .quizQuestion:
            return AnyView(quiz(component, runtime: runtime))
        case .spacer:
            return AnyView(
                Spacer()
                    .frame(height: 8)
            )
        }
    }
    
    private func containerView(_ component: MiniAppComponent, runtime: MiniAppRuntime) -> some View {
        VStack(alignment: .leading, spacing: component.props.style.spacingValue) {
            ForEach(component.children) { child in
                view(for: child, runtime: runtime)
            }
        }
        .padding(component.props.style.paddingValue)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: component.props.style.backgroundColor))
        .cornerRadius(component.props.style.cornerRadiusValue)
    }
    
    private func label(_ component: MiniAppComponent) -> some View {
        Text(component.props.text ?? component.props.label ?? "Label")
            .font(.system(size: component.props.style.fontSizeValue, weight: Font.Weight(component.props.style.fontWeight)))
            .foregroundColor(Color(hex: component.props.style.textColor))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(component.props.style.paddingValue)
            .background(Color(hex: component.props.style.backgroundColor).opacity(0.6))
            .cornerRadius(component.props.style.cornerRadiusValue)
    }
    
    private func button(_ component: MiniAppComponent, runtime: MiniAppRuntime) -> some View {
        Button(action: {
            runtime.performActions(for: component)
        }) {
            Text(component.props.label ?? component.props.text ?? "Button")
                .font(.system(size: component.props.style.fontSizeValue, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(component.props.style.paddingValue)
                .background(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: component.props.style.accentColor),
                        Color(hex: component.props.style.accentColor).opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .cornerRadius(component.props.style.cornerRadiusValue)
        }
    }
    
    private func toggle(_ component: MiniAppComponent, runtime: MiniAppRuntime) -> some View {
        let key = component.bindings?.stateKey ?? component.id
        let binding = Binding<Bool>(
            get: { runtime.state[key]?.boolValue ?? false },
            set: { runtime.state[key] = .bool($0) }
        )
        
        return Toggle(isOn: binding) {
            Text(component.props.label ?? component.props.text ?? "Toggle")
                .foregroundColor(Color(hex: component.props.style.textColor))
        }
        .padding(component.props.style.paddingValue)
        .background(Color(hex: component.props.style.backgroundColor))
        .cornerRadius(component.props.style.cornerRadiusValue)
    }
    
    private func list(_ component: MiniAppComponent) -> some View {
        VStack(alignment: .leading, spacing: component.props.style.spacingValue) {
            ForEach(component.props.items ?? [], id: \.self) { item in
                Text(item)
                    .foregroundColor(Color(hex: component.props.style.textColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color(hex: component.props.style.backgroundColor).opacity(0.4))
                    .cornerRadius(10)
            }
        }
        .padding(component.props.style.paddingValue)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: component.props.style.backgroundColor))
        .cornerRadius(component.props.style.cornerRadiusValue)
    }
    
    private func input(_ component: MiniAppComponent, runtime: MiniAppRuntime) -> some View {
        let key = component.bindings?.stateKey ?? component.id
        return VStack(alignment: .leading, spacing: 6) {
            if let label = component.props.label {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            TextField(
                component.props.placeholder ?? "Enter value",
                text: runtime.binding(for: key)
            )
            .textFieldStyle(.roundedBorder)
        }
        .padding(component.props.style.paddingValue)
        .background(Color(hex: component.props.style.backgroundColor))
        .cornerRadius(component.props.style.cornerRadiusValue)
    }
    
    private func remoteImage(_ component: MiniAppComponent) -> some View {
        VStack {
            if let urlString = component.props.imageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: component.props.style.backgroundColor))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(component.props.style.paddingValue)
    }
    
    private func quiz(_ component: MiniAppComponent, runtime: MiniAppRuntime) -> some View {
        VStack(alignment: .leading, spacing: component.props.style.spacingValue) {
            Text(component.props.text ?? "Question")
                .font(.system(size: component.props.style.fontSizeValue, weight: .semibold))
                .foregroundColor(Color(hex: component.props.style.textColor))
            
            ForEach(component.props.options ?? [], id: \.self) { option in
                Button(option) {
                    runtime.performActions(for: component)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(component.props.style.paddingValue)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: component.props.style.backgroundColor))
        .cornerRadius(component.props.style.cornerRadiusValue)
    }
}

private extension MiniAppComponentStyle {
    var paddingValue: CGFloat {
        let value = padding.isFinite && !padding.isNaN ? padding : 12.0
        return CGFloat(value)
    }
    var spacingValue: CGFloat {
        let value = spacing.isFinite && !spacing.isNaN ? spacing : 8.0
        return CGFloat(value)
    }
    var cornerRadiusValue: CGFloat {
        let value = cornerRadius.isFinite && !cornerRadius.isNaN ? cornerRadius : 14.0
        return CGFloat(value)
    }
    var fontSizeValue: CGFloat {
        let value = fontSize.isFinite && !fontSize.isNaN ? fontSize : 16.0
        return CGFloat(value)
    }
}

private extension Font.Weight {
    init(_ numericWeight: Double) {
        // Validate numeric weight to prevent NaN/infinite values
        let safeWeight = numericWeight.isFinite && !numericWeight.isNaN ? numericWeight : 400.0
        switch safeWeight {
        case ..<200: self = .ultraLight
        case ..<300: self = .thin
        case ..<400: self = .light
        case ..<500: self = .regular
        case ..<600: self = .medium
        case ..<700: self = .semibold
        case ..<800: self = .bold
        default: self = .heavy
        }
    }
}


