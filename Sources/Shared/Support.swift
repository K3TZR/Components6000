//
//  Support.swift
//  TestDiscoveryPackage/Shared
//
//  Created by Douglas Adams on 10/23/21.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Aliases

public typealias GuiClientId = String
public typealias Handle = UInt32
public typealias KeyValuesArray = [(key:String, value:String)]
public typealias ValuesArray = [String]

// ----------------------------------------------------------------------------
// MARK: - Extensions

public extension String {
  var handle          : Handle?         { self.hasPrefix("0x") ? UInt32(String(self.dropFirst(2)), radix: 16) : UInt32(self, radix: 16) }
  var bValue          : Bool            { (Int(self) ?? 0) == 1 ? true : false }
  var iValue          : Int             { Int(self) ?? 0 }
  
  /// Parse a String of <key=value>'s separated by the given Delimiter
  /// - Parameters:
  ///   - delimiter:          the delimiter between key values (defaults to space)
  ///   - keysToLower:        convert all Keys to lower case (defaults to YES)
  ///   - valuesToLower:      convert all values to lower case (defaults to NO)
  /// - Returns:              a KeyValues array
  func keyValuesArray(delimiter: String = " ", keysToLower: Bool = true, valuesToLower: Bool = false) -> KeyValuesArray {
    var kvArray = KeyValuesArray()
    
    // split it into an array of <key=value> values
    let keyAndValues = self.components(separatedBy: delimiter)
    
    for index in 0..<keyAndValues.count {
      // separate each entry into a Key and a Value
      var kv = keyAndValues[index].components(separatedBy: "=")
      
      // when "delimiter" is last character there will be an empty entry, don't include it
      if kv[0] != "" {
        // if no "=", set value to empty String (helps with strings with a prefix to KeyValues)
        // make sure there are no whitespaces before or after the entries
        if kv.count == 1 {
          
          // remove leading & trailing whitespace
          kvArray.append( (kv[0].trimmingCharacters(in: NSCharacterSet.whitespaces),"") )
        }
        if kv.count == 2 {
          // lowercase as needed
          if keysToLower { kv[0] = kv[0].lowercased() }
          if valuesToLower { kv[1] = kv[1].lowercased() }
          
          // remove leading & trailing whitespace
          kvArray.append( (kv[0].trimmingCharacters(in: NSCharacterSet.whitespaces),kv[1].trimmingCharacters(in: NSCharacterSet.whitespaces)) )
        }
      }
    }
    return kvArray
  }
  
  /// Parse a String of <value>'s separated by the given Delimiter
  /// - Parameters:
  ///   - delimiter:          the delimiter between values (defaults to space)
  ///   - valuesToLower:      convert all values to lower case (defaults to NO)
  /// - Returns:              a values array
  func valuesArray(delimiter: String = " ", valuesToLower: Bool = false) -> ValuesArray {
    guard self != "" else {return [String]() }
    
    // split it into an array of <value> values, lowercase as needed
    var array = valuesToLower ? self.components(separatedBy: delimiter).map {$0.lowercased()} : self.components(separatedBy: delimiter)
    array = array.map { $0.trimmingCharacters(in: .whitespaces) }
    
    return array
  }
}

/// Struct to hold a Semantic Version number
///     with provision for a Build Number
///
public struct Version {
    var major: Int = 1
    var minor: Int = 0
    var patch: Int = 0
    var build: Int = 1

    public init(_ versionString: String = "1.0.0") {
        let components = versionString.components(separatedBy: ".")
        switch components.count {
        case 3:
            major = Int(components[0]) ?? 1
            minor = Int(components[1]) ?? 0
            patch = Int(components[2]) ?? 0
            build = 1
        case 4:
            major = Int(components[0]) ?? 1
            minor = Int(components[1]) ?? 0
            patch = Int(components[2]) ?? 0
            build = Int(components[3]) ?? 1
        default:
            major = 1
            minor = 0
            patch = 0
            build = 1
        }
    }

    public init() {
        // only useful for Apps & Frameworks (which have a Bundle), not Packages
        let versions = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "?"
        let build   = Bundle.main.infoDictionary![kCFBundleVersionKey as String] as? String ?? "?"
        self.init(versions + ".\(build)")
    }

    public var longString: String { "\(major).\(minor).\(patch) (\(build))" }
    public var string: String { "\(major).\(minor).\(patch)" }

    static func == (lhs: Version, rhs: Version) -> Bool { lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch }

    static func < (lhs: Version, rhs: Version) -> Bool {

        switch (lhs, rhs) {

        case (let lhs, let rhs) where lhs == rhs: return false
        case (let lhs, let rhs) where lhs.major < rhs.major: return true
        case (let lhs, let rhs) where lhs.major == rhs.major && lhs.minor < rhs.minor: return true
        case (let lhs, let rhs) where lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch < rhs.patch: return true
        default: return false
        }
    }
}

extension Version {
  // Flex6000 specific versions
  public var isV3: Bool { major >= 3 }
  public var isV2NewApi: Bool { major == 2 && minor >= 5 }
  public var isGreaterThanV22: Bool { major >= 2 && minor >= 2 }
  public var isV2: Bool { major == 2 && minor < 5 }
  public var isV1: Bool { major == 1 }

  public var isNewApi: Bool { isV3 || isV2NewApi }
  public var isOldApi: Bool { isV1 || isV2 }
}
