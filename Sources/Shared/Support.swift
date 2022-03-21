//
//  Support.swift
//  Components6000/Shared
//
//  Created by Douglas Adams on 10/23/21.
//

import Foundation

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

// ----------------------------------------------------------------------------
// MARK: - Structs & Enums

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

public enum WanStatusType {
  case connect
  case publicIp
  case settings
}

public struct WanStatus: Equatable {
  
  public init(
    _ type: WanStatusType,
    _ name: String?,
    _ callsign: String?,
    _ serial: String?,
    _ wanHandle: String?,
    _ publicIp: String?
  )
  {
    self.type = type
    self.name = name
    self.callsign = callsign
    self.serial = serial
    self.wanHandle = wanHandle
    self.publicIp = publicIp
  }
  
  public var type: WanStatusType
  public var name: String?
  public var callsign: String?
  public var serial: String?
  public var wanHandle: String?
  public var publicIp: String?
}

public enum WanListenerError: Error {
  case kFailedToObtainIdToken
  case kFailedToConnect
}

public struct SmartlinkTestResult: Equatable {
  public var upnpTcpPortWorking = false
  public var upnpUdpPortWorking = false
  public var forwardTcpPortWorking = false
  public var forwardUdpPortWorking = false
  public var natSupportsHolePunch = false
  public var radioSerial = ""
  
  public init() {}
  
  // format the result as a String
  public var result: String {
        """
        Forward Tcp Port:\t\t\(forwardTcpPortWorking)
        Forward Udp Port:\t\t\(forwardUdpPortWorking)
        UPNP Tcp Port:\t\t\(upnpTcpPortWorking)
        UPNP Udp Port:\t\t\(upnpUdpPortWorking)
        Nat Hole Punch:\t\t\(natSupportsHolePunch)
        """
  }
  
  // result was Success / Failure
  public var success: Bool {
    (
      forwardTcpPortWorking == true &&
      forwardUdpPortWorking == true &&
      upnpTcpPortWorking == false &&
      upnpUdpPortWorking == false &&
      natSupportsHolePunch  == false) ||
    (
      forwardTcpPortWorking == false &&
      forwardUdpPortWorking == false &&
      upnpTcpPortWorking == true &&
      upnpUdpPortWorking == true &&
      natSupportsHolePunch  == false)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Functions

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
