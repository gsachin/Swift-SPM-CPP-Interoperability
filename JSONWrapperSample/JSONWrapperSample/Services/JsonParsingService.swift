//
//  JsonParsingService.swift
//  JSONWrapperSample
//

import Foundation
import JsonWrapper

protocol JsonParsingServiceProtocol {
    func parseJSON(_ jsonString: String) throws -> JsonParserWrapper
    func retrieveValue(from parser: JsonParserWrapper, forKey key: String) -> ParsingResult
    func checkKeyExists(in parser: JsonParserWrapper, key: String) -> Bool
    func buildJsonTree(from parser: JsonParserWrapper) -> JsonNode?
}

class JsonParserWrapper {
    let parser: JsonParser
    private(set) var memorySteps: [String] = []
    
    init(parser: JsonParser) {
        self.parser = parser
        addMemoryStep(" Parser created")
        addMemoryStep(" C++ handle allocated")
    }
    
    func addMemoryStep(_ step: String) {
        memorySteps.append(step)
    }
    
    deinit {
        // Parser's deinit will call json_destroy automatically
    }
}

class JsonParsingService: JsonParsingServiceProtocol {

    func parseJSON(_ jsonString: String) throws -> JsonParserWrapper {
        do {
            let parser = try JsonParser(jsonString: jsonString)
            let wrapper = JsonParserWrapper(parser: parser)
            return wrapper
        } catch {
            throw ParsingError.invalidJSON("Please check your input.")
        }
    }

    func retrieveValue(from parser: JsonParserWrapper, forKey key: String) -> ParsingResult {

        guard parser.parser.hasKey(key) else {
            return .failure(.keyNotFound(key))
        }

        guard let rawType = parser.parser.getType(key) else {
            return .failure(.typeError("Could not determine type for key '\(key)'"))
        }
        
        let valueType = JsonValueType(from: rawType)

        let valueString: String
        switch rawType {
        case "string":
            if let value = retrieveString(from: parser, key: key) {
                valueString = value
            } else {
                return .failure(.typeError("Failed to retrieve string value"))
            }
            
        case "number":
            if let value = retrieveNumber(from: parser, key: key) {
                valueString = value
            } else {
                return .failure(.typeError("Failed to retrieve numeric value"))
            }
            
        case "boolean":
            if let value = retrieveBoolean(from: parser, key: key) {
                valueString = value
            } else {
                return .failure(.typeError("Failed to retrieve boolean value"))
            }
            
        case "null":
            valueString = "null"
            parser.addMemoryStep(" Null value retrieved")
            
        case "array", "object":
            valueString = "Complex type (not supported)"
            parser.addMemoryStep(" Complex types not fully supported")
            
        default:
            valueString = "Unknown type"
            parser.addMemoryStep(" Unknown type")
        }

        parser.addMemoryStep(" Parser will be deallocated when released")
        
        let jsonValue = JsonValue(key: key, value: valueString, type: valueType)
        return .success(jsonValue, memorySteps: parser.memorySteps)
    }

    func checkKeyExists(in parser: JsonParserWrapper, key: String) -> Bool {
        return parser.parser.hasKey(key)
    }
    
    private func retrieveString(from parser: JsonParserWrapper, key: String) -> String? {
        guard let value = parser.parser.getString(key) else {
            return nil
        }
        
        // Track memory operations
        parser.addMemoryStep(" C-string allocated by C++")
        parser.addMemoryStep(" Swift String copied from C-string")
        parser.addMemoryStep(" C-string freed using json_free_string")
        
        return value
    }
    
    private func retrieveNumber(from parser: JsonParserWrapper, key: String) -> String? {
        if let intValue = parser.parser.getInt(key) {
            parser.addMemoryStep(" Numeric value retrieved (no heap allocation)")
            return "\(intValue)"
        }
        
        if let doubleValue = parser.parser.getDouble(key) {
            parser.addMemoryStep(" Numeric value retrieved (no heap allocation)")
            return "\(doubleValue)"
        }
        
        return nil
    }
    
    private func retrieveBoolean(from parser: JsonParserWrapper, key: String) -> String? {
        guard let boolValue = parser.parser.getBool(key) else {
            return nil
        }
        
        parser.addMemoryStep(" Boolean value retrieved (no heap allocation)")
        return "\(boolValue)"
    }
    
    // MARK: - Hierarchical Tree Building
    
    func buildJsonTree(from parser: JsonParserWrapper) -> JsonNode? {
        return buildNode(from: parser.parser, key: nil, level: 0)
    }
    
    private func buildNode(from parser: JsonParser, key: String?, level: Int) -> JsonNode? {
        // Get all keys if this is an object at root level
        guard let keys = parser.getKeys() else {
            return nil
        }
        
        // If we have a specific key, process that key
        if let key = key {
            guard let type = parser.getType(key) else { return nil }
            return buildNodeForKey(parser: parser, key: key, type: type, level: level)
        }
        
        // Root object - build children for all keys
        var children: [JsonNode] = []
        for childKey in keys {
            if let childNode = buildNodeForKey(parser: parser, key: childKey, type: parser.getType(childKey) ?? "unknown", level: level + 1) {
                children.append(childNode)
            }
        }
        
        return JsonNode(
            key: nil,
            value: .object(count: keys.count),
            type: .object,
            children: children,
            level: level
        )
    }
    
    private func buildNodeForKey(parser: JsonParser, key: String, type: String, level: Int) -> JsonNode? {
        let valueType = JsonValueType(from: type)
        
        switch type {
        case "string":
            if let value = parser.getString(key) {
                return JsonNode(key: key, value: .string(value), type: valueType, level: level)
            }
            
        case "number":
            if let intValue = parser.getInt(key) {
                return JsonNode(key: key, value: .number("\(intValue)"), type: valueType, level: level)
            }
            if let doubleValue = parser.getDouble(key) {
                return JsonNode(key: key, value: .number("\(doubleValue)"), type: valueType, level: level)
            }
            
        case "boolean":
            if let boolValue = parser.getBool(key) {
                return JsonNode(key: key, value: .boolean(boolValue), type: valueType, level: level)
            }
            
        case "null":
            return JsonNode(key: key, value: .null, type: valueType, level: level)
            
        case "array":
            if let arrayLength = parser.getArrayLength(key) {
                var children: [JsonNode] = []
                for index in 0..<arrayLength {
                    if let itemParser = parser.getArrayItem(key, at: index) {
                        if let itemNode = buildArrayItem(parser: itemParser, index: index, level: level + 1) {
                            children.append(itemNode)
                        }
                    }
                }
                return JsonNode(
                    key: key,
                    value: .array(count: arrayLength),
                    type: valueType,
                    children: children,
                    level: level
                )
            }
            
        case "object":
            if let objectParser = parser.getObject(key) {
                if let keys = objectParser.getKeys() {
                    var children: [JsonNode] = []
                    for childKey in keys {
                        if let childNode = buildNodeForKey(parser: objectParser, key: childKey, type: objectParser.getType(childKey) ?? "unknown", level: level + 1) {
                            children.append(childNode)
                        }
                    }
                    return JsonNode(
                        key: key,
                        value: .object(count: keys.count),
                        type: valueType,
                        children: children,
                        level: level
                    )
                }
            }
            
        default:
            break
        }
        
        return nil
    }
    
    private func buildArrayItem(parser: JsonParser, index: Int, level: Int) -> JsonNode? {
        // Get the root type of this array item
        guard let rootType = parser.getRootType() else {
            return nil
        }
        
        let valueType = JsonValueType(from: rootType)
        
        switch rootType {
        case "string":
            if let value = parser.getRootString() {
                return JsonNode(
                    key: "[\(index)]",
                    value: .string(value),
                    type: valueType,
                    level: level
                )
            }
            
        case "number":
            if let intValue = parser.getRootInt() {
                return JsonNode(
                    key: "[\(index)]",
                    value: .number("\(intValue)"),
                    type: valueType,
                    level: level
                )
            }
            if let doubleValue = parser.getRootDouble() {
                return JsonNode(
                    key: "[\(index)]",
                    value: .number("\(doubleValue)"),
                    type: valueType,
                    level: level
                )
            }
            
        case "boolean":
            if let boolValue = parser.getRootBool() {
                return JsonNode(
                    key: "[\(index)]",
                    value: .boolean(boolValue),
                    type: valueType,
                    level: level
                )
            }
            
        case "null":
            return JsonNode(
                key: "[\(index)]",
                value: .null,
                type: valueType,
                level: level
            )
            
        case "object":
            // It's an object in the array
            if let keys = parser.getKeys() {
                var children: [JsonNode] = []
                for childKey in keys {
                    if let childNode = buildNodeForKey(parser: parser, key: childKey, type: parser.getType(childKey) ?? "unknown", level: level + 1) {
                        children.append(childNode)
                    }
                }
                
                return JsonNode(
                    key: "[\(index)]",
                    value: .object(count: keys.count),
                    type: valueType,
                    children: children,
                    level: level
                )
            }
            
        case "array":
            // Nested array
            if let keys = parser.getKeys(), let arrayLength = parser.getArrayLength(keys.first ?? "") {
                return JsonNode(
                    key: "[\(index)]",
                    value: .array(count: arrayLength),
                    type: valueType,
                    level: level
                )
            }
            
        default:
            break
        }
        
        return nil
    }
}
