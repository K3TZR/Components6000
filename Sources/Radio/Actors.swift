//
//  Actors.swift
//  Components6000/Radio
//
//  Created by Douglas Adams on 2/6/22.
//

import Foundation
import IdentifiedCollections

import Shared

final public actor Actors: Equatable {
  
  public static func == (lhs: Actors, rhs: Actors) -> Bool {
    // object equality since it is a "sharedInstance"
    lhs === rhs
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  // Dynamic Model Collections
  public var amplifiers = IdentifiedArrayOf<Amplifier>()
  public var bandSettings = IdentifiedArrayOf<BandSetting>()
  public var daxIqStreams = IdentifiedArrayOf<DaxIqStream>()
  public var daxMicAudioStreams = IdentifiedArrayOf<DaxMicAudioStream>()
  public var daxRxAudioStreams = IdentifiedArrayOf<DaxRxAudioStream>()
  public var daxTxAudioStreams = IdentifiedArrayOf<DaxTxAudioStream>()
  public var equalizers = IdentifiedArrayOf<Equalizer>()
  public var memories = IdentifiedArrayOf<Memory>()
  public var meters = IdentifiedArrayOf<Meter>()
  public var panadapters = IdentifiedArrayOf<Panadapter>()
  public var profiles = IdentifiedArrayOf<Profile>()
  public var remoteRxAudioStreams = IdentifiedArrayOf<RemoteRxAudioStream>()
  public var remoteTxAudioStreams = IdentifiedArrayOf<RemoteTxAudioStream>()
  public var slices = IdentifiedArrayOf<Slice>()
  public var tnfs = IdentifiedArrayOf<Tnf>()
  public var usbCables = IdentifiedArrayOf<UsbCable>()
  public var waterfalls = IdentifiedArrayOf<Waterfall>()
  public var xvtrs = IdentifiedArrayOf<Xvtr>()
  
  // Static Models
  public internal(set) var atu: Atu!
  public internal(set) var cwx: Cwx!
  public internal(set) var gps: Gps!
  public internal(set) var interlock: Interlock!
//  public internal(set) var netCwStream: NetCwStream!
  public internal(set) var transmit: Transmit!
  public internal(set) var wan: Wan!
  public internal(set) var waveform: Waveform!
//  public internal(set) var wanServer: WanServer!

  
  
  
//  public var meters: IdentifiedArrayOf<Meter> {
//    get { objectQ.sync { _meters } }
//    set { objectQ.sync(flags: .barrier) { _meters = newValue }}}
//
//  public var panadapters: IdentifiedArrayOf<Panadapter> {
//    get { objectQ.sync { _panadapters } }
//    set { objectQ.sync(flags: .barrier) { _panadapters = newValue }}}
//
//  public var waterfalls: IdentifiedArrayOf<Waterfall> {
//    get { objectQ.sync { _waterfalls } }
//    set { objectQ.sync(flags: .barrier) { _waterfalls = newValue }}}
//
//  private let objectQ = DispatchQueue(label: "Objects" + ".objectQ", attributes: [.concurrent])
//
//  private var _meters = IdentifiedArrayOf<Meter>()
//  private var _panadapters = IdentifiedArrayOf<Panadapter>()
//  private var _waterfalls = IdentifiedArrayOf<Waterfall>()

  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var sharedInstance = Actors()
  private init() {}
  
  private var _initialized = false
  //  let _log = LogProxy.sharedInstance.log
    
  private let _log: Log = { msg,level,function,file,line in
    NotificationCenter.default.post(name: logEntryNotification, object: LogEntry(msg, level, function, file, line))
  }

  
  public func addObject(_ object: Any) {
    
    switch object {
    case is Tnf:
      tnfs.append(object as! Tnf)
    default:
      break
    }
  }
  

  
  // ----------------------------------------------------------------------------
  // MARK: - Internal types

  enum TnfTokens : String {
    case depth
    case frequency = "freq"
    case permanent
    case width
  }
  
  
  /// Parse Tnf key/value pairs
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValues
  func parseTnfProperties(_ id: ObjectId, _ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = TnfTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Tnf, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .depth:      tnfs[id: id]?.depth = property.value.uValue
      case .frequency:  tnfs[id: id]?.frequency = property.value.mhzToHz
      case .permanent:  tnfs[id: id]?.permanent = property.value.bValue
      case .width:      tnfs[id: id]?.width = property.value.mhzToHz
      }
      // is the Tnf initialized?
      if !_initialized && tnfs[id: id]!.frequency != 0 {
        // YES, the Radio (hardware) has acknowledged this Tnf
        _initialized = true
        
        // notify all observers
        _log("Tnf, added: id = \(id), frequency = \(tnfs[id: id]!.frequency)", .debug, #function, #file, #line)
        //        NC.post(.tnfHasBeenAdded, object: self as Any?)
      }
    }
  }
}
