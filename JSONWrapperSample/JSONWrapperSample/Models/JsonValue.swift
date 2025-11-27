//
//  JsonValue.swift
//  JSONWrapperSample
//

import Foundation

/// Represents a parsed JSON value with its metadata
struct JsonValue {
    let key: String
    let value: String
    let type: JsonValueType
    
    var displayValue: String {
        switch type {
        case .string:
            return "\"\(value)\""
        default:
            return value
        }
    }
}

/// Enum representing JSON value types
enum JsonValueType: String {
    case string = "String"
    case number = "Number"
    case boolean = "Boolean"
    case null = "Null"
    case array = "Array"
    case object = "Object"
    case unknown = "Unknown"
    
    init(from rawType: String) {
        switch rawType.lowercased() {
        case "string": self = .string
        case "number": self = .number
        case "boolean": self = .boolean
        case "null": self = .null
        case "array": self = .array
        case "object": self = .object
        default: self = .unknown
        }
    }
}

/// Result type for parsing operations
enum ParsingResult {
    case success(JsonValue, memorySteps: [String])
    case failure(ParsingError)
}

/// Structured error types for parsing errors
enum ParsingError: Error {
    case invalidJSON(String)
    case keyNotFound(String)
    case typeError(String)
    case unknown(String)
    
    var userMessage: String {
        switch self {
        case .invalidJSON(let details):
            return "Invalid JSON format. \(details)"
        case .keyNotFound(let key):
            return "Key '\(key)' does not exist in JSON"
        case .typeError(let details):
            return "Type error: \(details)"
        case .unknown(let message):
            return "Unexpected error: \(message)"
        }
    }
}
