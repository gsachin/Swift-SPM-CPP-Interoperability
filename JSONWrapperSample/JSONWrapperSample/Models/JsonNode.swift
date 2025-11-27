//
//  JsonNode.swift
//  JSONWrapperSample
//

import Foundation

/// Represents a node in a hierarchical JSON tree structure
struct JsonNode: Identifiable, Hashable {
    let id = UUID()
    let key: String?
    let value: JsonNodeValue
    let type: JsonValueType
    var children: [JsonNode]
    let level: Int
    
    init(key: String? = nil, value: JsonNodeValue, type: JsonValueType, children: [JsonNode] = [], level: Int = 0) {
        self.key = key
        self.value = value
        self.type = type
        self.children = children
        self.level = level
    }
    
    var displayKey: String {
        key ?? "root"
    }
    
    var displayValue: String {
        switch value {
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return num
        case .boolean(let bool):
            return bool ? "true" : "false"
        case .null:
            return "null"
        case .array(let count):
            return "[\(count) items]"
        case .object(let count):
            return "{\(count) keys}"
        }
    }
    
    var isExpandable: Bool {
        switch type {
        case .array, .object:
            return !children.isEmpty
        default:
            return false
        }
    }
    
    var icon: String {
        switch type {
        case .string:
            return "textformat"
        case .number:
            return "number"
        case .boolean:
            return "switch.2"
        case .null:
            return "minus.circle"
        case .array:
            return "list.bullet"
        case .object:
            return "curlybraces"
        default:
            return "questionmark"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: JsonNode, rhs: JsonNode) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents the value of a JSON node
enum JsonNodeValue: Hashable {
    case string(String)
    case number(String)
    case boolean(Bool)
    case null
    case array(count: Int)
    case object(count: Int)
}
