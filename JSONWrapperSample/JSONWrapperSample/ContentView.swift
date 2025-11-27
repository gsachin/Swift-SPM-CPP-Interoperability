//
//  ContentView.swift
//  JSONWrapperSample
//

import SwiftUI

/// Main view for JSON parsing demonstration
struct ContentView: View {
    
    @StateObject private var viewModel = ViewModelFactory.makeDefault()
    
    // MARK: Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // JSON Input Section
                jsonInputSection
                
                Divider()
                
                // Parse Button
                parseButton
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                
                Divider()
                
                // Tab View
                tabSection
            }
            .navigationTitle("JSON Parser Demo")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Parsing...")
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: View Components
    
    private var jsonInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("JSON Input", systemImage: "doc.text")
                .font(.headline)
            
            TextEditor(text: $viewModel.jsonInput)
                .frame(minHeight: 120, maxHeight: 180)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .font(.system(.body, design: .monospaced))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .padding()
    }
    
    private var parseButton: some View {
        Button(action: {
            viewModel.parseAndRetrieveValue()
        }) {
            HStack {
                Image(systemName: "play.circle.fill")
                Text("Parse JSON")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private var tabSection: some View {
        VStack(spacing: 0) {
            // Custom Tab Bar
            HStack(spacing: 0) {
                ForEach(ViewTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.title3)
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            viewModel.selectedTab == tab ?
                            Color.blue.opacity(0.1) : Color.clear
                        )
                        .foregroundColor(
                            viewModel.selectedTab == tab ?
                            Color.blue : Color.secondary
                        )
                    }
                }
            }
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Tab Content
            Group {
                switch viewModel.selectedTab {
                case .tree:
                    treeTabContent
                case .raw:
                    rawJsonTabContent
                }
            }
        }
    }
    
    private var treeTabContent: some View {
        VStack(spacing: 0) {
            // Toolbar for tree view
            HStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Button(action: {
                    viewModel.expandAll()
                }) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    viewModel.collapseAll()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Tree view
            JsonTreeView(
                rootNode: viewModel.jsonTree,
                expandedNodes: $viewModel.expandedNodes,
                searchText: $viewModel.searchText
            )
        }
    }
    
    private var keyValueTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Key Selection Section
                keySelectionSection
                
                Divider()
                
                // Results Section
                if let value = viewModel.retrievedValue {
                    resultsSection(value: value)
                }
                
                // Error Section
                if viewModel.showError {
                    errorSection
                }
                
                // Memory Management Info
                memoryManagementSection
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var rawJsonTabContent: some View {
        ScrollView {
            Text(viewModel.jsonInput)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var keySelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Select Key to Retrieve", systemImage: "key")
                .font(.headline)
            
            Picker("Key", selection: $viewModel.selectedKey) {
                ForEach(viewModel.availableKeys, id: \.self) { key in
                    Text(key).tag(key)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private func resultsSection(value: JsonValue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Retrieved Value", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Key:")
                        .fontWeight(.semibold)
                    Text(value.key)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Value:")
                        .fontWeight(.semibold)
                    Text(value.displayValue)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Type:")
                        .fontWeight(.semibold)
                    Text(value.type.rawValue)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var errorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(viewModel.errorMessage)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var memoryManagementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Memory Management", systemImage: "memorychip")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(viewModel.memoryInfo, id: \.self) { step in
                    Text(step)
                        .font(.caption)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: Preview

#Preview {
    ContentView()
}
