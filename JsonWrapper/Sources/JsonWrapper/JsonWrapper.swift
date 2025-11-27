import Foundation
import CxxJsonParser

public class JsonParser {
    private var handle: JsonParserHandle?

    public init(jsonString: String) throws {
        guard let handle = json_parse(jsonString) else {
            throw JsonError.invalidJSON
        }
        self.handle = handle
    }
    
    deinit {
        if let handle = handle {
            json_destroy(handle)
        }
    }

    public func getString(_ key: String) -> String? {
        guard let handle = handle else { return nil }
        
        guard let cString = json_get_string(handle, key) else {
            return nil
        }
        
        defer { json_free_string(cString) }
        return String(cString: cString)
    }

    public func getInt(_ key: String) -> Int? {
        guard let handle = handle else { return nil }
        
        guard hasKey(key), getType(key) == "number" else {
            return nil
        }
        
        return Int(json_get_int(handle, key))
    }

    public func getDouble(_ key: String) -> Double? {
        guard let handle = handle else { return nil }
        
        guard hasKey(key), getType(key) == "number" else {
            return nil
        }
        
        return json_get_double(handle, key)
    }

    public func getBool(_ key: String) -> Bool? {
        guard let handle = handle else { return nil }
        
        guard hasKey(key), getType(key) == "boolean" else {
            return nil
        }
        
        return json_get_bool(handle, key)
    }

    public func hasKey(_ key: String) -> Bool {
        guard let handle = handle else { return false }
        return json_has_key(handle, key)
    }

    public func getType(_ key: String) -> String? {
        guard let handle = handle else { return nil }
        
        guard let cString = json_get_type(handle, key) else {
            return nil
        }
        
        defer { json_free_string(cString) }
        return String(cString: cString)
    }

    public subscript(key: String) -> Any? {
        guard hasKey(key) else { return nil }
        
        switch getType(key) {
        case "string":
            return getString(key)
        case "number":
            // Try int first, fallback to double
            if let intValue = getInt(key) {
                return intValue
            }
            return getDouble(key)
        case "boolean":
            return getBool(key)
        case "null":
            return nil
        default:
            return nil
        }
    }
    
    public func getKeys() -> [String]? {
        guard let handle = handle else { return nil }
        
        guard let cString = json_get_keys(handle) else {
            return nil
        }
        
        defer { json_free_string(cString) }
        let keysString = String(cString: cString)
        
        if keysString.isEmpty {
            return []
        }
        
        return keysString.split(separator: ",").map(String.init)
    }
    
    public func getArrayLength(_ key: String) -> Int? {
        guard let handle = handle else { return nil }
        
        guard hasKey(key), getType(key) == "array" else {
            return nil
        }
        
        let length = json_get_array_length(handle, key)
        return length > 0 ? Int(length) : nil
    }
    
    public func getArrayItem(_ key: String, at index: Int) -> JsonParser? {
        guard let handle = handle else { return nil }
        
        guard hasKey(key), getType(key) == "array" else {
            return nil
        }
        
        guard let itemHandle = json_get_array_item(handle, key, Int32(index)) else {
            return nil
        }
        
        // Create a JsonParser with the existing handle (it manages deallocation)
        return JsonParser(handle: itemHandle)
    }
    
    public func getObject(_ key: String) -> JsonParser? {
        guard let handle = handle else { return nil }
        
        guard hasKey(key), getType(key) == "object" else {
            return nil
        }
        
        guard let objectHandle = json_get_object(handle, key) else {
            return nil
        }
        
        // Create a JsonParser with the existing handle (it manages deallocation)
        return JsonParser(handle: objectHandle)
    }
    
    // MARK: - Root Value Methods (for array items and nested values)
    
    public func getRootType() -> String? {
        guard let handle = handle else { return nil }
        
        guard let cString = json_get_root_type(handle) else {
            return nil
        }
        
        defer { json_free_string(cString) }
        return String(cString: cString)
    }
    
    public func getRootString() -> String? {
        guard let handle = handle else { return nil }
        
        guard let cString = json_get_root_string(handle) else {
            return nil
        }
        
        defer { json_free_string(cString) }
        return String(cString: cString)
    }
    
    public func getRootInt() -> Int? {
        guard let handle = handle else { return nil }
        
        guard getRootType() == "number" else {
            return nil
        }
        
        return Int(json_get_root_int(handle))
    }
    
    public func getRootDouble() -> Double? {
        guard let handle = handle else { return nil }
        
        guard getRootType() == "number" else {
            return nil
        }
        
        return json_get_root_double(handle)
    }
    
    public func getRootBool() -> Bool? {
        guard let handle = handle else { return nil }
        
        guard getRootType() == "boolean" else {
            return nil
        }
        
        return json_get_root_bool(handle)
    }
    
    // Internal initializer for nested parsers
    private init(handle: JsonParserHandle) {
        self.handle = handle
    }
}

public enum JsonError: Error {
    case invalidJSON
    case keyNotFound(String)
    case typeMismatch(String, expected: String, actual: String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidJSON:
            return "Invalid JSON string"
        case .keyNotFound(let key):
            return "Key '\(key)' not found in JSON"
        case .typeMismatch(let key, let expected, let actual):
            return "Type mismatch for key '\(key)': expected \(expected), got \(actual)"
        }
    }
}
