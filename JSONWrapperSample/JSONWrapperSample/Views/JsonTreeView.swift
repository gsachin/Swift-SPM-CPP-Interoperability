//
//  JsonTreeView.swift
//  JSONWrapperSample
//

import SwiftUI

/// Displays a hierarchical tree view of JSON data with expandable/collapsible nodes
struct JsonTreeView: View {
    let rootNode: JsonNode?
    @Binding var expandedNodes: Set<UUID>
    @Binding var searchText: String
    
    var body: some View {
        if let root = rootNode {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredNodes(root), id: \.id) { node in
                        JsonTreeNodeView(
                            node: node,
                            isExpanded: expandedNodes.contains(node.id),
                            onToggle: {
                                toggleNode(node)
                            }
                        )
                    }
                }
                .padding()
            }
        } else {
            ContentUnavailableView(
                "No JSON Data",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Parse JSON to view the tree structure")
            )
        }
    }
    
    private func toggleNode(_ node: JsonNode) {
        if expandedNodes.contains(node.id) {
            expandedNodes.remove(node.id)
        } else {
            expandedNodes.insert(node.id)
        }
    }
    
    private func filteredNodes(_ root: JsonNode) -> [JsonNode] {
        if searchText.isEmpty {
            return flattenTree(root)
        }
        return flattenTree(root).filter { node in
            node.displayKey.localizedCaseInsensitiveContains(searchText) ||
            node.displayValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func flattenTree(_ node: JsonNode) -> [JsonNode] {
        var result: [JsonNode] = [node]
        
        if expandedNodes.contains(node.id) && node.isExpandable {
            for child in node.children {
                result.append(contentsOf: flattenTree(child))
            }
        }
        
        return result
    }
}

/// Individual node view in the tree
struct JsonTreeNodeView: View {
    let node: JsonNode
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Indentation
            ForEach(0..<node.level, id: \.self) { _ in
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 2)
                    .padding(.leading, 8)
            }
            
            // Expand/Collapse button
            if node.isExpandable {
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .frame(width: 20)
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
                    .frame(width: 20)
            }
            
            // Icon
            Image(systemName: node.icon)
                .font(.caption)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            // Key
            if let key = node.key {
                Text(key)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(":")
                    .foregroundColor(.secondary)
            }
            
            // Value
            Text(node.displayValue)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(valueColor)
                .lineLimit(1)
            
            Spacer()
            
            // Type badge
            Text(node.type.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(badgeColor.opacity(0.2))
                .foregroundColor(badgeColor)
                .cornerRadius(4)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(node.level % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
        )
        .contentShape(Rectangle())
    }
    
    private var iconColor: Color {
        switch node.type {
        case .string: return .green
        case .number: return .blue
        case .boolean: return .orange
        case .null: return .gray
        case .array: return .purple
        case .object: return .pink
        default: return .secondary
        }
    }
    
    private var valueColor: Color {
        switch node.type {
        case .string: return .green
        case .number: return .blue
        case .boolean: return .orange
        case .null: return .gray
        default: return .secondary
        }
    }
    
    private var badgeColor: Color {
        switch node.type {
        case .string: return .green
        case .number: return .blue
        case .boolean: return .orange
        case .null: return .gray
        case .array: return .purple
        case .object: return .pink
        default: return .secondary
        }
    }
}

#Preview {
    let sampleNode = JsonNode(
        key: nil,
        value: .object(count: 3),
        type: .object,
        children: [
            JsonNode(key: "name", value: .string("John"), type: .string, level: 1),
            JsonNode(key: "age", value: .number("30"), type: .number, level: 1),
            JsonNode(
                key: "address",
                value: .object(count: 2),
                type: .object,
                children: [
                    JsonNode(key: "city", value: .string("New York"), type: .string, level: 2),
                    JsonNode(key: "zip", value: .string("10001"), type: .string, level: 2)
                ],
                level: 1
            )
        ],
        level: 0
    )
    
    JsonTreeView(
        rootNode: sampleNode,
        expandedNodes: .constant([sampleNode.id]),
        searchText: .constant("")
    )
}
