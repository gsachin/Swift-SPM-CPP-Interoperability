#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque pointer to hide C++ implementation from Swift
typedef void* JsonParserHandle;

// Create a JSON parser from a string
// Returns NULL if parsing fails
JsonParserHandle json_parse(const char* json_string);

// Get string value for a key
// Returns NULL if key doesn't exist or value is not a string
// Caller must free the returned string using json_free_string
char* json_get_string(JsonParserHandle handle, const char* key);

// Get integer value for a key
// Returns the value, or 0 if key doesn't exist or value is not an integer
// Use json_has_key to check if key exists before calling
int json_get_int(JsonParserHandle handle, const char* key);

// Get double value for a key
// Returns the value, or 0.0 if key doesn't exist or value is not a number
double json_get_double(JsonParserHandle handle, const char* key);

// Get boolean value for a key
// Returns the value, or false if key doesn't exist or value is not a boolean
bool json_get_bool(JsonParserHandle handle, const char* key);

// Check if a key exists in the JSON object
bool json_has_key(JsonParserHandle handle, const char* key);

// Get the type of value for a key as a string
// Returns: "null", "boolean", "number", "string", "array", "object", or "unknown"
// Caller must free the returned string using json_free_string
char* json_get_type(JsonParserHandle handle, const char* key);

// Get all keys in the JSON object as a comma-separated string
// Returns NULL if handle is invalid or not an object
// Caller must free the returned string using json_free_string
char* json_get_keys(JsonParserHandle handle);

// Get the length of an array for a given key
// Returns 0 if key doesn't exist or value is not an array
int json_get_array_length(JsonParserHandle handle, const char* key);

// Get array item at index as a new parser handle for a given key
// Returns NULL if key doesn't exist, value is not an array, or index is out of bounds
// Caller must call json_destroy on the returned handle
JsonParserHandle json_get_array_item(JsonParserHandle handle, const char* key, int index);

// Get nested object as a new parser handle for a given key
// Returns NULL if key doesn't exist or value is not an object
// Caller must call json_destroy on the returned handle
JsonParserHandle json_get_object(JsonParserHandle handle, const char* key);

// Get the type of the root value (for array items and nested values)
// Returns: "null", "boolean", "number", "string", "array", "object", or "unknown"
// Caller must free the returned string using json_free_string
char* json_get_root_type(JsonParserHandle handle);

// Get root value as string (for primitive array items)
// Returns NULL if root value is not a string
// Caller must free the returned string using json_free_string
char* json_get_root_string(JsonParserHandle handle);

// Get root value as integer (for primitive array items)
int json_get_root_int(JsonParserHandle handle);

// Get root value as double (for primitive array items)
double json_get_root_double(JsonParserHandle handle);

// Get root value as boolean (for primitive array items)
bool json_get_root_bool(JsonParserHandle handle);

// Free a string returned by json functions
void json_free_string(char* str);

// Destroy the JSON parser and free memory
void json_destroy(JsonParserHandle handle);

#ifdef __cplusplus
}
#endif
