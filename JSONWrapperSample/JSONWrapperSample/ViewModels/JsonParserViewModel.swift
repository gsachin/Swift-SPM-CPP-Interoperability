//
//  JsonParserViewModel.swift
//  JSONWrapperSample
//

import Foundation
import Combine
import JsonWrapper

@MainActor
class JsonParserViewModel: ObservableObject {
    
    @Published var jsonInput: String = """
    {
        "name": "John Doe",
        "age": 30,
        "isStudent": false,
        "gpa": 3.85,
        "scores": [95, 88, 92, 100],
        "address": {
            "street": "123 Main St",
            "city": "New York",
            "zipCode": "10001",
            "coordinates": [40.7128, -74.0060]
        },
        "hobbies": ["reading", "coding", "gaming"],
        "friends": [
            {"name": "Alice", "age": 28},
            {"name": "Bob", "age": 32}
        ],
        "metadata": {
            "created": "2023-01-01",
            "updated": "2023-12-31",
            "tags": ["student", "developer", "active"],
            "flags": [true, false, true]
        }
    }
    """
    
    @Published var selectedKey: String = "name"
    @Published var retrievedValue: JsonValue?
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var memoryInfo: [String] = ["Memory managed correctly "]
    @Published var isLoading: Bool = false
    
    // Tree view state
    @Published var jsonTree: JsonNode?
    @Published var expandedNodes: Set<UUID> = []
    @Published var searchText: String = ""
    @Published var selectedTab: ViewTab = .tree
    
    private let parsingService: JsonParsingServiceProtocol
    private var currentParser: JsonParserWrapper?

    
    let availableKeys = ["name", "age", "isStudent", "gpa", "nonExistentKey"]

    init(parsingService: JsonParsingServiceProtocol = JsonParsingService()) {
        self.parsingService = parsingService
    }

    func parseAndRetrieveValue() {
        resetState()
        isLoading = true

        do {
            let parser = try parsingService.parseJSON(jsonInput)
            currentParser = parser
            memoryInfo = parser.memorySteps
            
            // Build tree
            jsonTree = parsingService.buildJsonTree(from: parser)
            
            // Auto-expand root level nodes
            if let tree = jsonTree {
                expandedNodes.insert(tree.id)
                for child in tree.children {
                    expandedNodes.insert(child.id)
                }
            }
            
            // Retrieve value for key-value view
            let result = parsingService.retrieveValue(from: parser, forKey: selectedKey)
            handleParsingResult(result)
            
        } catch let error as ParsingError {
            handleError(error)
        } catch {
            handleError(.unknown(error.localizedDescription))
        }
        
        isLoading = false
    }
    
    func expandAll() {
        guard let tree = jsonTree else { return }
        expandAllNodes(tree)
    }
    
    func collapseAll() {
        expandedNodes.removeAll()
    }
    
    private func expandAllNodes(_ node: JsonNode) {
        expandedNodes.insert(node.id)
        for child in node.children {
            expandAllNodes(child)
        }
    }

    func getValueTypeDescription() -> String {
        guard let parser = currentParser else {
            return "Unknown"
        }
        
        guard let rawType = parser.parser.getType(selectedKey) else {
            return "Unknown"
        }
        
        return JsonValueType(from: rawType).rawValue
    }

    func keyExists() -> Bool {
        guard let parser = currentParser else {
            return false
        }
        return parsingService.checkKeyExists(in: parser, key: selectedKey)
    }
    
    private func resetState() {
        retrievedValue = nil
        errorMessage = ""
        showError = false
        memoryInfo = ["Parsing JSON..."]
    }
    
    private func handleParsingResult(_ result: ParsingResult) {
        switch result {
        case .success(let value, let steps):
            retrievedValue = value
            memoryInfo = steps
            showError = false
            
        case .failure(let error):
            handleError(error)
        }
    }
    
    private func handleError(_ error: ParsingError) {
        errorMessage = error.userMessage
        showError = true
        
        switch error {
        case .invalidJSON:
            memoryInfo = [" Parse failed (no memory allocated)"]
        case .keyNotFound:
            memoryInfo.append(" Parser deallocated (deinit called)")
        default:
            memoryInfo = [" Error occurred"]
        }
    }
}

// MARK: - View Tabs

enum ViewTab: String, CaseIterable {
    case tree = "Tree"
    case raw = "Raw JSON"
    
    var icon: String {
        switch self {
        case .tree: return "list.tree"
        case .raw: return "doc.text"
        }
    }
}

// MARK: - ViewModel Factory

/// Factory for creating ViewModels with different configurations
enum ViewModelFactory {
    
    /// Creates a ViewModel with the default service
    static func makeDefault() -> JsonParserViewModel {
        return JsonParserViewModel(parsingService: JsonParsingService())
    }
    
    /// Creates a ViewModel with a custom service (useful for testing)
    static func makeWithService(_ service: JsonParsingServiceProtocol) -> JsonParserViewModel {
        return JsonParserViewModel(parsingService: service)
    }
}
