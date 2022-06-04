//
//  MeterCollection.swift
//  
//
//  Created by Douglas Adams on 4/18/22.
//

import Foundation
import Combine
import IdentifiedCollections

import Shared

/// Meter Collection implementation
///
///      Meter objects are added / removed by the incoming TCP messages.
///      Meter values are periodically updated by a UDP stream.
///

@globalActor
public actor MeterCollection {
  
  public static var meterPublisher = PassthroughSubject<Meter, Never>()
  public static var metersAreStreaming = false

  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static let shared = MeterCollection()
  private init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var meters: IdentifiedArrayOf<Meter> = []
  
  public enum MeterToken: String {
    case desc
    case fps
    case high       = "hi"
    case low
    case name       = "nam"
    case group      = "num"
    case source     = "src"
    case units      = "unit"
  }
  
  public enum Units : String {
    case none
    case amps
    case db
    case dbfs
    case dbm
    case degc
    case degf
    case percent
    case rpm
    case swr
    case volts
    case watts
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
//  private let _log = LogProxy.sharedInstance.log

  private let _log: Log = { msg,level,function,file,line in
    NotificationCenter.default.post(name: logEntryNotification, object: LogEntry(msg, level, function, file, line))
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Parse a Meter status message
  /// - Parameters:
  ///   - properties:     a KeyValuesArray of Meter properties
  ///   - inUse:          false = "to be deleted"
  public func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // is the object in use?
    if inUse {
      // YES, extract the Meter Number from the first KeyValues entry
      let components = properties[0].key.components(separatedBy: ".")
      if components.count != 2 {return }
      
      // get the id
      if let id = components[0].objectId {
        // does the meter exist?
        
        if meters[id: id] == nil {
          // NO, create a new Meter & add it to the Meters collection
          meters[id: id] = Meter(id)
        }
        // pass the key values to the Meter for parsing
        parseProperties(id, properties: properties )
      }
      
    } else {
      // NO, get the Id
      if let id = properties[0].key.components(separatedBy: " ")[0].objectId {
        remove(id)
      }
    }
  }
  
  /// Set the value of a Meter
  /// - Parameters:
  ///   - id:         the MeterId of the specified meter
  ///   - value:      the current value
  public func setValue(_ id: MeterId, value: Float) {
    meters[id: id]!.value = value
    updateViewModel()
  }

  /// Remove the specified Meter
  /// - Parameter id:     a MeterId
  public func remove(_ id: MeterId) {
    meters.remove(id: id)
    updateViewModel()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse Meter key/value pairs
  /// - Parameters:
  ///   - id:               the id of the Meter
  ///   - properties:       a KeyValuesArray of Meter properties
  private func parseProperties(_ id: MeterId, properties: KeyValuesArray) {
    // process each key/value pair, <n.key=value>
    for property in properties {
      // separate the Meter Number from the Key
      let numberAndKey = property.key.components(separatedBy: ".")
      
      // get the Key
      let key = numberAndKey[1]
      
      // check for unknown Keys
      guard let token = MeterToken(rawValue: key) else {
        // log it and ignore the Key
        _log("Meter, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known Keys, in alphabetical order
      switch token {
        
      case .desc:     meters[id: id]!.desc = property.value
      case .fps:      meters[id: id]!.fps = property.value.iValue
      case .high:     meters[id: id]!.high = property.value.fValue
      case .low:      meters[id: id]!.low = property.value.fValue
      case .name:     meters[id: id]!.name = property.value.lowercased()
      case .group:    meters[id: id]!.group = property.value
      case .source:   meters[id: id]!.source = property.value.lowercased()
      case .units:    meters[id: id]!.units = property.value.lowercased()
      }
    }
    if !meters[id: id]!.initialized && meters[id: id]!.group != "" && meters[id: id]!.units != "" {
      // the Radio (hardware) has acknowledged this Meter
      meters[id: id]!.initialized = true
      _log("Meter \(id) added: \(meters[id: id]!.name), source = \(meters[id: id]!.source), group = \(meters[id: id]!.group)", .debug, #function, #file, #line)
    }
    updateViewModel()
  }
  
  /// Synchronize the viewModel
  private func updateViewModel() {
    Task {
      ViewModel.shared.meters = meters
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Process the Vita struct containing Meter data
  /// - Parameters:
  ///   - vita:        a Vita struct
  static func vitaProcessor(_ vita: Vita) {
    let kDbDbmDbfsSwrDenom: Float = 128.0   // denominator for Db, Dbm, Dbfs, Swr
    let kDegDenom: Float = 64.0             // denominator for Degc, Degf
    
    var meterIds = [UInt16]()
    
    if metersAreStreaming == false {
      metersAreStreaming = true
      // log the start of the stream
//      LogProxy.sharedInstance.log("Meter stream \(vita.streamId.hex): started", .info, #function, #file, #line)
      NotificationCenter.default.post(name: logEntryNotification, object: LogEntry("Meter stream \(vita.streamId.hex): started", .info, #function, #file, #line))
    }
    
    // NOTE:  there is a bug in the Radio (as of v2.2.8) that sends
    //        multiple copies of meters, this code ignores the duplicates
    
    vita.payloadData.withUnsafeBytes { (payloadPtr) in
      // four bytes per Meter
      let numberOfMeters = Int(vita.payloadSize / 4)
      
      // pointer to the first Meter number / Meter value pair
      let ptr16 = payloadPtr.bindMemory(to: UInt16.self)
      
      // for each meter in the Meters packet
      for i in 0..<numberOfMeters {
        // get the Meter id and the Meter value
        let id: UInt16 = CFSwapInt16BigToHost(ptr16[2 * i])
        let value: UInt16 = CFSwapInt16BigToHost(ptr16[(2 * i) + 1])
        
        // is this a duplicate?
        if !meterIds.contains(id) {
          // NO, add it to the list
          meterIds.append(id)
          
          // find the meter (if present) & update it
          Task {
            if let meter = await MeterCollection.shared.meters[id: id] {
              //          meter.streamHandler( value)
              let newValue = Int16(bitPattern: value)
              let previousValue = meter.value
              
              // check for unknown Units
              guard let token = Units(rawValue: meter.units) else {
                //      // log it and ignore it
                //      _log("Meter \(desc) \(description) \(group) \(name) \(source): unknown units - \(units))", .warning, #function, #file, #line)
                return
              }
              var adjNewValue: Float = 0.0
              switch token {
                
              case .db, .dbm, .dbfs, .swr:        adjNewValue = Float(exactly: newValue)! / kDbDbmDbfsSwrDenom
              case .volts, .amps:                 adjNewValue = Float(exactly: newValue)! / 256.0
              case .degc, .degf:                  adjNewValue = Float(exactly: newValue)! / kDegDenom
              case .rpm, .watts, .percent, .none: adjNewValue = Float(exactly: newValue)!
              }
              // did it change?
              if adjNewValue != previousValue {
                await MeterCollection.shared.setValue(id, value: adjNewValue)
              }
              meterPublisher.send(meter)
            }
          }
        }
      }
    }
  }
}
