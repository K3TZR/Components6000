//
//  Support.swift
//  Components6000/Shared
//
//  Created by Douglas Adams on 10/23/21.
//

import Foundation
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - Constants

public let kVersionSupported = Version("3.2.34")
public let kConnected = "connected"
public let kDisconnected = "disconnected"
public let kNoError = "0"
public let kNotInUse = "in_use=0"
public let kRemoved = "removed"

// ----------------------------------------------------------------------------
// MARK: - Aliases

public typealias AmplifierId = Handle
public typealias AntennaPort = String
public typealias BandId = ObjectId
public typealias DaxIqStreamId = StreamId
public typealias DaxMicStreamId = StreamId
public typealias DaxRxStreamId = StreamId
public typealias DaxTxStreamId = StreamId
public typealias EqualizerId = String
public typealias GuiClientId = String
public typealias Handle = UInt32
public typealias Hz = Int
public typealias IdToken = String
public typealias KeyValuesArray = [(key:String, value:String)]
public typealias MHz = Double
public typealias MemoryId = ObjectId
public typealias MeterId = ObjectId
public typealias MeterName  = String
public typealias MicrophonePort = String
public typealias ObjectId = UInt16
public typealias PanadapterStreamId = StreamId
public typealias ProfileId = String
public typealias ProfileName = String
public typealias RadioId = String
public typealias RemoteRxStreamId = StreamId
public typealias RemoteTxStreamId = StreamId
public typealias ReplyHandler = (_ command: String, _ seqNumber: SequenceNumber, _ responseValue: String, _ reply: String) -> Void
public typealias ReplyTuple = (replyTo: ReplyHandler?, command: String)
public typealias RfGainValue = String
public typealias SequenceNumber = UInt
public typealias SliceId = ObjectId
public typealias StreamId = UInt32
public typealias TnfId = ObjectId
public typealias UsbCableId = String
public typealias ValuesArray = [String]
public typealias WaterfallStreamId = StreamId
public typealias XvtrId = ObjectId

public enum ConnectionType: String, Equatable {
  case gui = "Radio"
  case nonGui = "Station"
}

public struct PickerSelection: Equatable {
  public init(_ packet: Packet, _ station: String? = nil, _ disconnectHandle: Handle? = nil) {
    self.packet = packet
    self.station = station
    self.disconnectHandle = disconnectHandle
  }

  public var packet: Packet
  public var station: String?
  public var disconnectHandle: Handle?
}

public enum ButtonType: Equatable {
  case primary(String)
  case secondary(String)
}

public struct AlertView: Equatable, Identifiable {
  
  public init(
    title: String,
    message: String? = nil,
    button1Text: String? = nil
//    button2: ButtonType? = nil
  )
  {
    self.title = title
    self.message = message
    self.button1Text = button1Text
//    self.button2 = button2
  }
  public var id: String { self.title }
  public var title: String
  public var message: String?
  public var button1Text: String?
//  public var button2: ButtonType?
}

// ----------------------------------------------------------------------------
// MARK: - Extensions

public extension Bool {
    var as1or0Int   : Int     { self ? 1 : 0 }
    var as1or0      : String  { self ? "1" : "0" }
    var asTrueFalse : String  { self ? "True" : "False" }
    var asTF        : String  { self ? "T" : "F" }
    var asOnOff     : String  { self ? "on" : "off" }
    var asPassFail  : String  { self ? "PASS" : "FAIL" }
    var asYesNo     : String  { self ? "YES" : "NO" }
}

extension FileManager {
  
  public static func appFolder(for bundleIdentifier: String) -> URL {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask )
    let appFolderUrl = urls.first!.appendingPathComponent( bundleIdentifier )
    
    // does the folder exist?
    if !fileManager.fileExists( atPath: appFolderUrl.path ) {
      
      // NO, create it
      do {
        try fileManager.createDirectory( at: appFolderUrl, withIntermediateDirectories: true, attributes: nil)
      } catch let error as NSError {
        fatalError("Error creating App Support folder: \(error.localizedDescription)")
      }
    }
    return appFolderUrl
  }
}

extension URL {
  public static var appSupport : URL { return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first! }
}

public extension String {
  var bValue          : Bool            { (Int(self) ?? 0) == 1 ? true : false }
  var cgValue         : CGFloat         { CGFloat(self) }
  var dValue          : Double          { Double(self) ?? 0 }
  var fValue          : Float           { Float(self) ?? 0 }
  var handle          : Handle?         { self.hasPrefix("0x") ? UInt32(String(self.dropFirst(2)), radix: 16) : UInt32(self, radix: 16) }
  var iValue          : Int             { Int(self) ?? 0 }
  var iValueOpt       : Int?            { self == "-1" ? nil : Int(self) }
  var list            : [String]        { self.components(separatedBy: ",") }
  var mhzToHz         : Hz              { Hz( (Double(self) ?? 0) * 1_000_000 ) }
  var objectId        : ObjectId?       { UInt16(self, radix: 10) }
  var sequenceNumber  : SequenceNumber  { UInt(self, radix: 10) ?? 0 }
  var streamId        : StreamId?       { self.hasPrefix("0x") ? UInt32(String(self.dropFirst(2)), radix: 16) : UInt32(self, radix: 16) }
  var trimmed         : String          { self.trimmingCharacters(in: CharacterSet.whitespaces) }
  var tValue          : Bool            { self.lowercased() == "true" ? true : false }
  var uValue          : UInt            { UInt(self) ?? 0 }
  var uValue32        : UInt32          { UInt32(self) ?? 0 }
  
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

  /// Replace spaces with a specified value
  /// - Parameters:
  ///   - value:      the String to replace spaces
  /// - Returns:      the adjusted String
  func replacingSpaces(with value: String = "\u{007F}") -> String {
      return self.replacingOccurrences(of: " ", with: value)
  }
  
  enum TruncationPosition {
    case head
    case middle
    case tail
  }
  
  func truncated(limit: Int, position: TruncationPosition = .tail, leader: String = "...") -> String {
    guard self.count > limit else { return self }
    
    switch position {
    case .head:
      return leader + self.suffix(limit)
    case .middle:
      let headCharactersCount = Int(ceil(Float(limit - leader.count) / 2.0))
      
      let tailCharactersCount = Int(floor(Float(limit - leader.count) / 2.0))
      
      return "\(self.prefix(headCharactersCount))\(leader)\(self.suffix(tailCharactersCount))"
    case .tail:
      return self.prefix(limit) + leader
    }
  }
}

public extension CGFloat {
  /// Force a CGFloat to be within a min / max value range
  /// - Parameters:
  ///   - min:        min CGFloat value
  ///   - max:        max CGFloat value
  /// - Returns:      adjusted value
  func bracket(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
    
    var value = self
    if self < min { value = min }
    if self > max { value = max }
    return value
  }
  
  /// Create a CGFloat from a String
  /// - Parameters:
  ///   - string:     a String
  ///
  /// - Returns:      CGFloat value of String or 0
  init(_ string: String) {
    self = CGFloat(Float(string) ?? 0)
  }
  
  /// Format a String with the value of a CGFloat
  /// - Parameters:
  ///   - width:      number of digits before the decimal point
  ///   - precision:  number of digits after the decimal point
  ///   - divisor:    divisor
  /// - Returns:      a String representation of the CGFloat
  private func floatToString(width: Int, precision: Int, divisor: CGFloat) -> String {
    return String(format: "%\(width).\(precision)f", self / divisor)
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
  
  public static func == (lhs: Version, rhs: Version) -> Bool { lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch }
  
  public static func < (lhs: Version, rhs: Version) -> Bool {
    switch (lhs, rhs) {
      
    case (let lhs, let rhs) where lhs == rhs: return false
    case (let lhs, let rhs) where lhs.major < rhs.major: return true
    case (let lhs, let rhs) where lhs.major == rhs.major && lhs.minor < rhs.minor: return true
    case (let lhs, let rhs) where lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch < rhs.patch: return true
    default: return false
    }
  }
  public static func >= (lhs: Version, rhs: Version) -> Bool {
    switch (lhs, rhs) {
      
    case (let lhs, let rhs) where lhs == rhs: return true
    case (let lhs, let rhs) where lhs.major > rhs.major: return true
    case (let lhs, let rhs) where lhs.major == rhs.major && lhs.minor > rhs.minor: return true
    case (let lhs, let rhs) where lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch > rhs.patch: return true
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

public extension Int {
  var hzToMhz: String { String(format: "%02.6f", Double(self) / 1_000_000.0) }
}
public extension UInt16 {
  var hex: String { return String(format: "0x%04X", self) }
  func toHex(_ format: String = "0x%04X") -> String { String(format: format, self) }
}

public extension UInt32 {
  var hex: String { return String(format: "0x%08X", self) }
  func toHex(_ format: String = "0x%08X") -> String { String(format: format, self) }
}

extension String {
  /// Replace spaces and equal signs in a CWX Macro with alternate characters
  /// - Returns:      the String after processing
  public func fix(spaceReplacement: String = "\u{007F}", equalsReplacement: String = "*") -> String {
    var newString: String = ""
    var quotes = false
    
    // We could have spaces inside quotes, so we have to convert them to something else for key/value parsing.
    // We could also have an equal sign '=' (for Prosign BT) inside the quotes, so we're converting to a '*' so that the split on "="
    // will still work.  This will prevent the character '*' from being stored in a macro.  Using the ascii byte for '=' will not work.
    for char in self {
      if char == "\"" {
        quotes = !quotes
        
      } else if char == " " && quotes {
        newString += spaceReplacement
        
      } else if char == "=" && quotes {
        newString += equalsReplacement
        
      } else {
        newString.append(char)
      }
    }
    return newString
  }
  
  /// Undo any changes made to a Cwx Macro string by the fix method    ///
  /// - Returns:          the String after undoing the fixString changes
  public func unfix(spaceReplacement: String = "\u{007F}", equalsReplacement: String = "*") -> String {
    var newString: String = ""
    
    for char in self {
      if char == Character(spaceReplacement) {
        newString += " "
        
      } else if char == Character(equalsReplacement) {
        newString += "="
        
      } else {
        newString.append(char)
      }
    }
    return newString
  }
}

public func getBundleInfo() -> (domain: String, appName: String) {
  let bundleIdentifier = Bundle.main.bundleIdentifier ?? "net.k3tzr.XCGWrapper"
  let separator = bundleIdentifier.lastIndex(of: ".")!
  let appName = String(bundleIdentifier.suffix(from: bundleIdentifier.index(separator, offsetBy: 1)))
  let domain = String(bundleIdentifier.prefix(upTo: separator))
  return (domain, appName)
}

public func setupLogFolder(_ info: (domain: String, appName: String)) -> URL? {
  func createAsNeeded(_ folder: String) -> URL? {
    let fileManager = FileManager.default
    let folderUrl = URL.appSupport.appendingPathComponent( folder )
    // try to create it
    do {
      try fileManager.createDirectory( at: folderUrl, withIntermediateDirectories: true, attributes: nil)
    } catch {
      return nil
    }
    return folderUrl
  }

  return createAsNeeded(info.domain + "." + info.appName + "/Logs")
}

// ----------------------------------------------------------------------------
// MARK: - Property Wrappers

@propertyWrapper
public class Atomic<Value> {  
  public var projectedValue: Atomic { return self }
  
  private var value: Value
  private var queue: DispatchQueue
  
  public init(_ wrappedValue: Value, _ queue: DispatchQueue) {
    self.value = wrappedValue
    self.queue = queue
  }
  
  public var wrappedValue: Value {
    get { queue.sync { value }}
    set { queue.sync { value = newValue }} }
  
  public func mutate(_ mutation: (inout Value) -> Void) {
    return queue.sync { mutation(&value) }
  }
}
