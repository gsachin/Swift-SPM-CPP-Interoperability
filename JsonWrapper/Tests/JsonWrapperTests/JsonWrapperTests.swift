import Testing
@testable import JsonWrapper

struct JsonWrapperTests {
    
    @Test func testValidJSONParsing() async throws {
        let jsonString = #"{"name": "John", "age": 30, "active": true}"#
        let parser = try JsonParser(jsonString: jsonString)
        
        #expect(parser.hasKey("name"))
        #expect(parser.hasKey("age"))
        #expect(parser.hasKey("active"))
    }
    
    @Test func testInvalidJSONParsing() async throws {
        let invalidJSON = #"{invalid json}"#
        
        var didThrow = false
        do {
            _ = try JsonParser(jsonString: invalidJSON)
        } catch {
            didThrow = true
        }
        
        #expect(didThrow)
    }
    
    @Test func testGetString() async throws {
        let jsonString = #"{"name": "John Doe", "city": "New York"}"#
        let parser = try JsonParser(jsonString: jsonString)
        
        let name = parser.getString("name")
        #expect(name == "John Doe")
        
        let city = parser.getString("city")
        #expect(city == "New York")
    }
    
    @Test func testGetInt() async throws {
        let jsonString = #"{"age": 30, "count": 100}"#
        let parser = try JsonParser(jsonString: jsonString)
        
        let age = parser.getInt("age")
        #expect(age == 30)
        
        let count = parser.getInt("count")
        #expect(count == 100)
    }
    
    @Test func testGetDouble() async throws {
        let jsonString = #"{"price": 19.99, "tax": 0.08}"#
        let parser = try JsonParser(jsonString: jsonString)
        
        let price = parser.getDouble("price")
        #expect(price == 19.99)
        
        let tax = parser.getDouble("tax")
        #expect(tax == 0.08)
    }
    
    @Test func testGetBool() async throws {
        let jsonString = #"{"active": true, "verified": false}"#
        let parser = try JsonParser(jsonString: jsonString)
        
        let active = parser.getBool("active")
        #expect(active == true)
        
        let verified = parser.getBool("verified")
        #expect(verified == false)
    }
    
    @Test func testMemoryManagement() async throws {
        // Create and destroy multiple parsers to test memory management
        for i in 0..<100 {
            let jsonString = #"{"count": \#(i), "message": "Test \#(i)"}"#
            let parser = try JsonParser(jsonString: jsonString)
            
            let count = parser.getInt("count")
            #expect(count == i)
            
            let message = parser.getString("message")
            #expect(message == "Test \(i)")
        }
    }
    
    // MARK: - Hierarchical JSON Tests
    
    @Test func testGetKeys() async throws {
        let jsonString = #"{"name": "John", "age": 30, "city": "NYC"}"#
        let parser = try JsonParser(jsonString: jsonString)
        
        let keys = parser.getKeys()
        #expect(keys != nil)
        #expect(keys?.count == 3)
        #expect(keys?.contains("name") == true)
        #expect(keys?.contains("age") == true)
        #expect(keys?.contains("city") == true)
    }
    
    @Test func testGetArrayLength() async throws {
        let jsonString = #"{"items": [1, 2, 3, 4, 5], "tags": ["a", "b"]}"#
        let parser = try JsonParser(jsonString: jsonString)
        
        let itemsLength = parser.getArrayLength("items")
        #expect(itemsLength == 5)
        
        let tagsLength = parser.getArrayLength("tags")
        #expect(tagsLength == 2)
        
        let nonExistent = parser.getArrayLength("missing")
        #expect(nonExistent == nil)
    }
    
    @Test func testGetArrayItem() async throws {
        let jsonString = #"{"numbers": [10, 20, 30]}"#
        let parser = try JsonParser(jsonString: jsonString)
        
        guard let item0 = parser.getArrayItem("numbers", at: 0) else {
            Issue.record("Failed to get array item at index 0")
            return
        }
        
        // Array items at root level should support getting keys if they're objects
        // For primitive values, this is a simplified test
        #expect(item0 != nil)
    }
    
    @Test func testGetObject() async throws {
        let jsonString = #"{"person": {"name": "Alice", "age": 25}}"#
        let parser = try JsonParser(jsonString: jsonString)
        
        guard let personParser = parser.getObject("person") else {
            Issue.record("Failed to get nested object")
            return
        }
        
        let name = personParser.getString("name")
        #expect(name == "Alice")
        
        let age = personParser.getInt("age")
        #expect(age == 25)
    }
    
    @Test func testNestedObjectsAndArrays() async throws {
        let jsonString = #"""
        {
            "users": [
                {"name": "Alice", "age": 25},
                {"name": "Bob", "age": 30}
            ],
            "metadata": {
                "count": 2,
                "tags": ["active", "verified"]
            }
        }
        """#
        
        let parser = try JsonParser(jsonString: jsonString)
        
        // Test nested object
        guard let metadata = parser.getObject("metadata") else {
            Issue.record("Failed to get metadata object")
            return
        }
        
        let count = metadata.getInt("count")
        #expect(count == 2)
        
        let tagsLength = metadata.getArrayLength("tags")
        #expect(tagsLength == 2)
        
        // Test array of objects
        let usersLength = parser.getArrayLength("users")
        #expect(usersLength == 2)
        
        guard let user0 = parser.getArrayItem("users", at: 0) else {
            Issue.record("Failed to get first user")
            return
        }
        
        let userName = user0.getString("name")
        #expect(userName == "Alice")
    }
    
    @Test func testHierarchicalMemoryManagement() async throws {
        // Test memory management with nested structures
        for _ in 0..<50 {
            let jsonString = #"""
            {
                "level1": {
                    "level2": {
                        "level3": {
                            "value": "deep"
                        }
                    }
                }
            }
            """#
            
            let parser = try JsonParser(jsonString: jsonString)
            
            guard let level1 = parser.getObject("level1"),
                  let level2 = level1.getObject("level2"),
                  let level3 = level2.getObject("level3") else {
                Issue.record("Failed to navigate nested objects")
                return
            }
            
            let value = level3.getString("value")
            #expect(value == "deep")
            
            // All parsers should be deallocated when they go out of scope
        }
    }
    
    @Test func testArrayOfPrimitives() async throws {
        let jsonString = #"""
        {
            "numbers": [1, 2, 3, 4, 5],
            "strings": ["apple", "banana", "cherry"],
            "bools": [true, false, true]
        }
        """#
        
        let parser = try JsonParser(jsonString: jsonString)
        
        // Test number array
        let numbersLength = parser.getArrayLength("numbers")
        #expect(numbersLength == 5)
        
        guard let num0 = parser.getArrayItem("numbers", at: 0) else {
            Issue.record("Failed to get first number")
            return
        }
        #expect(num0.getRootType() == "number")
        #expect(num0.getRootInt() == 1)
        
        guard let num4 = parser.getArrayItem("numbers", at: 4) else {
            Issue.record("Failed to get fifth number")
            return
        }
        #expect(num4.getRootInt() == 5)
        
        // Test string array
        let stringsLength = parser.getArrayLength("strings")
        #expect(stringsLength == 3)
        
        guard let str0 = parser.getArrayItem("strings", at: 0) else {
            Issue.record("Failed to get first string")
            return
        }
        #expect(str0.getRootType() == "string")
        #expect(str0.getRootString() == "apple")
        
        guard let str2 = parser.getArrayItem("strings", at: 2) else {
            Issue.record("Failed to get third string")
            return
        }
        #expect(str2.getRootString() == "cherry")
        
        // Test boolean array
        let boolsLength = parser.getArrayLength("bools")
        #expect(boolsLength == 3)
        
        guard let bool0 = parser.getArrayItem("bools", at: 0) else {
            Issue.record("Failed to get first boolean")
            return
        }
        #expect(bool0.getRootType() == "boolean")
        #expect(bool0.getRootBool() == true)
        
        guard let bool1 = parser.getArrayItem("bools", at: 1) else {
            Issue.record("Failed to get second boolean")
            return
        }
        #expect(bool1.getRootBool() == false)
    }
    
    @Test func testArrayOfObjects() async throws {
        let jsonString = #"""
        {
            "users": [
                {"name": "Alice", "age": 25, "active": true},
                {"name": "Bob", "age": 30, "active": false},
                {"name": "Charlie", "age": 35, "active": true}
            ]
        }
        """#
        
        let parser = try JsonParser(jsonString: jsonString)
        
        let usersLength = parser.getArrayLength("users")
        #expect(usersLength == 3)
        
        // Test first user
        guard let user0 = parser.getArrayItem("users", at: 0) else {
            Issue.record("Failed to get first user")
            return
        }
        #expect(user0.getRootType() == "object")
        #expect(user0.getString("name") == "Alice")
        #expect(user0.getInt("age") == 25)
        #expect(user0.getBool("active") == true)
        
        // Test second user
        guard let user1 = parser.getArrayItem("users", at: 1) else {
            Issue.record("Failed to get second user")
            return
        }
        #expect(user1.getString("name") == "Bob")
        #expect(user1.getInt("age") == 30)
        #expect(user1.getBool("active") == false)
        
        // Test third user
        guard let user2 = parser.getArrayItem("users", at: 2) else {
            Issue.record("Failed to get third user")
            return
        }
        #expect(user2.getString("name") == "Charlie")
        #expect(user2.getInt("age") == 35)
        #expect(user2.getBool("active") == true)
    }
    
    @Test func testMixedArrayTypes() async throws {
        let jsonString = #"""
        {
            "data": {
                "primitives": [100, 200, 300],
                "objects": [
                    {"id": 1, "value": "first"},
                    {"id": 2, "value": "second"}
                ],
                "nested": {
                    "tags": ["tag1", "tag2", "tag3"]
                }
            }
        }
        """#
        
        let parser = try JsonParser(jsonString: jsonString)
        
        guard let data = parser.getObject("data") else {
            Issue.record("Failed to get data object")
            return
        }
        
        // Test primitive array in nested object
        let primitivesLength = data.getArrayLength("primitives")
        #expect(primitivesLength == 3)
        
        guard let prim1 = data.getArrayItem("primitives", at: 1) else {
            Issue.record("Failed to get primitive at index 1")
            return
        }
        #expect(prim1.getRootInt() == 200)
        
        // Test object array in nested object
        let objectsLength = data.getArrayLength("objects")
        #expect(objectsLength == 2)
        
        guard let obj0 = data.getArrayItem("objects", at: 0) else {
            Issue.record("Failed to get object at index 0")
            return
        }
        #expect(obj0.getInt("id") == 1)
        #expect(obj0.getString("value") == "first")
        
        // Test deeply nested array
        guard let nested = data.getObject("nested") else {
            Issue.record("Failed to get nested object")
            return
        }
        
        let tagsLength = nested.getArrayLength("tags")
        #expect(tagsLength == 3)
        
        guard let tag0 = nested.getArrayItem("tags", at: 0) else {
            Issue.record("Failed to get first tag")
            return
        }
        #expect(tag0.getRootString() == "tag1")
    }
}
