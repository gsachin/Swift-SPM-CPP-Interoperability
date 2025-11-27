#include "JsonWrapper.h"
#include "nlohmann/json.hpp"
#include <cstring>
#include <exception>

using json = nlohmann::json;

struct JsonParser {
    json data;
    std::string error;
    
    JsonParser() = default;
};

extern "C" {

JsonParserHandle json_parse(const char* json_string) {
    if (!json_string) {
        return nullptr;
    }
    
    try {
        auto* parser = new JsonParser();
        parser->data = json::parse(json_string);
        return static_cast<JsonParserHandle>(parser);
    } catch (const std::exception& e) {
        return nullptr;
    }
}

char* json_get_string(JsonParserHandle handle, const char* key) {
    if (!handle || !key) {
        return nullptr;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.contains(key)) {
            return nullptr;
        }
        
        if (!parser->data[key].is_string()) {
            return nullptr;
        }
        
        std::string value = parser->data[key].get<std::string>();
        char* result = static_cast<char*>(malloc(value.length() + 1));
        if (result) {
            strcpy(result, value.c_str());
        }
        return result;
    } catch (...) {
        return nullptr;
    }
}

int json_get_int(JsonParserHandle handle, const char* key) {
    if (!handle || !key) {
        return 0;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.contains(key)) {
            return 0;
        }
        
        if (!parser->data[key].is_number_integer()) {
            return 0;
        }
        
        return parser->data[key].get<int>();
    } catch (...) {
        return 0;
    }
}

double json_get_double(JsonParserHandle handle, const char* key) {
    if (!handle || !key) {
        return 0.0;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.contains(key)) {
            return 0.0;
        }
        
        if (!parser->data[key].is_number()) {
            return 0.0;
        }
        
        return parser->data[key].get<double>();
    } catch (...) {
        return 0.0;
    }
}

bool json_get_bool(JsonParserHandle handle, const char* key) {
    if (!handle || !key) {
        return false;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.contains(key)) {
            return false;
        }
        
        if (!parser->data[key].is_boolean()) {
            return false;
        }
        
        return parser->data[key].get<bool>();
    } catch (...) {
        return false;
    }
}

bool json_has_key(JsonParserHandle handle, const char* key) {
    if (!handle || !key) {
        return false;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        return parser->data.contains(key);
    } catch (...) {
        return false;
    }
}

char* json_get_type(JsonParserHandle handle, const char* key) {
    if (!handle || !key) {
        return nullptr;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.contains(key)) {
            return nullptr;
        }
        
        std::string type_name;
        const auto& value = parser->data[key];
        
        if (value.is_null()) {
            type_name = "null";
        } else if (value.is_boolean()) {
            type_name = "boolean";
        } else if (value.is_number()) {
            type_name = "number";
        } else if (value.is_string()) {
            type_name = "string";
        } else if (value.is_array()) {
            type_name = "array";
        } else if (value.is_object()) {
            type_name = "object";
        } else {
            type_name = "unknown";
        }
        
        char* result = static_cast<char*>(malloc(type_name.length() + 1));
        if (result) {
            strcpy(result, type_name.c_str());
        }
        return result;
    } catch (...) {
        return nullptr;
    }
}

char* json_get_keys(JsonParserHandle handle) {
    if (!handle) {
        return nullptr;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.is_object()) {
            return nullptr;
        }
        
        std::string keys_str;
        bool first = true;
        
        for (auto it = parser->data.begin(); it != parser->data.end(); ++it) {
            if (!first) {
                keys_str += ",";
            }
            keys_str += it.key();
            first = false;
        }
        
        char* result = static_cast<char*>(malloc(keys_str.length() + 1));
        if (result) {
            strcpy(result, keys_str.c_str());
        }
        return result;
    } catch (...) {
        return nullptr;
    }
}

int json_get_array_length(JsonParserHandle handle, const char* key) {
    if (!handle || !key) {
        return 0;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.contains(key)) {
            return 0;
        }
        
        if (!parser->data[key].is_array()) {
            return 0;
        }
        
        return static_cast<int>(parser->data[key].size());
    } catch (...) {
        return 0;
    }
}

JsonParserHandle json_get_array_item(JsonParserHandle handle, const char* key, int index) {
    if (!handle || !key || index < 0) {
        return nullptr;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.contains(key)) {
            return nullptr;
        }
        
        if (!parser->data[key].is_array()) {
            return nullptr;
        }
        
        const auto& array = parser->data[key];
        if (index >= static_cast<int>(array.size())) {
            return nullptr;
        }
        
        auto* new_parser = new JsonParser();
        new_parser->data = array[index];
        return static_cast<JsonParserHandle>(new_parser);
    } catch (...) {
        return nullptr;
    }
}

JsonParserHandle json_get_object(JsonParserHandle handle, const char* key) {
    if (!handle || !key) {
        return nullptr;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.contains(key)) {
            return nullptr;
        }
        
        if (!parser->data[key].is_object()) {
            return nullptr;
        }
        
        auto* new_parser = new JsonParser();
        new_parser->data = parser->data[key];
        return static_cast<JsonParserHandle>(new_parser);
    } catch (...) {
        return nullptr;
    }
}

char* json_get_root_type(JsonParserHandle handle) {
    if (!handle) {
        return nullptr;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        std::string type_name;
        const auto& value = parser->data;
        
        if (value.is_null()) {
            type_name = "null";
        } else if (value.is_boolean()) {
            type_name = "boolean";
        } else if (value.is_number()) {
            type_name = "number";
        } else if (value.is_string()) {
            type_name = "string";
        } else if (value.is_array()) {
            type_name = "array";
        } else if (value.is_object()) {
            type_name = "object";
        } else {
            type_name = "unknown";
        }
        
        char* result = static_cast<char*>(malloc(type_name.length() + 1));
        if (result) {
            strcpy(result, type_name.c_str());
        }
        return result;
    } catch (...) {
        return nullptr;
    }
}

char* json_get_root_string(JsonParserHandle handle) {
    if (!handle) {
        return nullptr;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.is_string()) {
            return nullptr;
        }
        
        std::string value = parser->data.get<std::string>();
        char* result = static_cast<char*>(malloc(value.length() + 1));
        if (result) {
            strcpy(result, value.c_str());
        }
        return result;
    } catch (...) {
        return nullptr;
    }
}

int json_get_root_int(JsonParserHandle handle) {
    if (!handle) {
        return 0;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.is_number_integer()) {
            return 0;
        }
        
        return parser->data.get<int>();
    } catch (...) {
        return 0;
    }
}

double json_get_root_double(JsonParserHandle handle) {
    if (!handle) {
        return 0.0;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.is_number()) {
            return 0.0;
        }
        
        return parser->data.get<double>();
    } catch (...) {
        return 0.0;
    }
}

bool json_get_root_bool(JsonParserHandle handle) {
    if (!handle) {
        return false;
    }
    
    try {
        auto* parser = static_cast<JsonParser*>(handle);
        
        if (!parser->data.is_boolean()) {
            return false;
        }
        
        return parser->data.get<bool>();
    } catch (...) {
        return false;
    }
}

void json_free_string(char* str) {
    if (str) {
        free(str);
    }
}

void json_destroy(JsonParserHandle handle) {
    if (handle) {
        auto* parser = static_cast<JsonParser*>(handle);
        delete parser;
    }
}

} // extern "C"
