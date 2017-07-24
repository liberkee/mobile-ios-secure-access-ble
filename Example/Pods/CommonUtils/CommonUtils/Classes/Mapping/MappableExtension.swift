//
// Created by Ruben Pelzer on 19-06-17.
//

import ObjectMapper

/// General rule for the mapper
public class MapperValidationRule {

    fileprivate let value: Any?
    fileprivate let key: String

    public init(key: String, value: Any?) {
        self.value = value
        self.key = key
    }

    func validates(map _: Map, immutableMappable _: ImmutableMappable) -> Bool {
        return true
    }
}

/// Rule to validate if value is the same before and after the mapping
public class MapperOptionalRule: MapperValidationRule {

    override func validates(map: Map, immutableMappable _: ImmutableMappable) -> Bool {
        return map.JSON[key] == nil || (map.JSON[key] != nil && value != nil) || map.JSON[key]! is NSNull
    }
}

/// Rule to validate if the property is not nil
public class MapperRequiredRule: MapperValidationRule {

    override func validates(map _: Map, immutableMappable: ImmutableMappable) -> Bool {
        return value != nil
    }
}

public extension ImmutableMappable {

    /// Validate if the model is mapped regarding all rules
    ///
    /// - Parameters:
    ///   - rules: Array of MapperValidationRule
    ///   - map: The current map
    func validate(with rules: [MapperValidationRule], map: Map) -> Bool {
        var valid = true
        for rule in rules {
            if !rule.validates(map: map, immutableMappable: self) {
                #if DEBUG
                    print("😡😡😡 ObjectMapper failed on \'\(type(of: self))\' because of the property \'\(rule.key)\'")
                #endif
                valid = false
            }
        }
        return valid
    }
}
