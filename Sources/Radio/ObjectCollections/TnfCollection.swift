//
//  TnfCollection.swift
//  
//
//  Created by Douglas Adams on 4/16/22.
//

import Foundation
import IdentifiedCollections

import Shared

@globalActor
public actor TnfCollection {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static let shared = TnfCollection()
  private init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var tnfs: IdentifiedArrayOf<Tnf> = []
  
  public enum TnfToken : String {
    case depth
    case frequency = "freq"
    case permanent
    case width
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log = LogProxy.sharedInstance.log
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Parse a Tnf status message
  /// - Parameters:
  ///   - properties:     a KeyValuesArray of Tnf properties
  ///   - inUse:          false = "to be deleted"
  public func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // Note: Tnf does not send status on removal
    
    // get the Id
    if let id = properties[0].key.objectId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if tnfs[id: id] == nil {
          // NO, create a new Tnf & add it to the Tnfs collection
          tnfs[id: id] = Tnf(id)
        }
        // pass the remaining key values to the Tnf for parsing
        parseProperties(id: id, properties: Array(properties.dropFirst(1)) )
      }
    }
  }
  
  public func setProperty(radio: Radio, _ id: TnfId, property: TnfToken, value: Any) {
    switch property {
    case .depth:       sendCommand( radio, id, .depth, value)
    case .frequency:   sendCommand( radio, id, .frequency, (value as! Hz).hzToMhz)
    case .permanent:   sendCommand( radio, id, .permanent, (value as! Bool).as1or0)
    case .width:       sendCommand( radio, id, .width, (value as! Hz).hzToMhz)
    }
  }

//  public func getProperty( _ id: TnfId, property: TnfToken) -> Any? {    
//    switch property {
//    case .depth:       return tnfs[id: id]?.depth as Any
//    case .frequency:   return tnfs[id: id]?.frequency as Any
//    case .permanent:   return tnfs[id: id]?.permanent as Any
//    case .width:       return tnfs[id: id]?.width as Any
//    }
//  }

  /// Remove the specified Tnf
  /// - Parameter id:     a TnfId
  public func remove(_ id: TnfId) {
    tnfs.remove(id: id)
    updateViewModel()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse Tnf key/value pairs
  /// - Parameters:
  ///   - id:               the id of the Tnf
  ///   - properties:       a KeyValuesArray of Tnf properties
  private func parseProperties(id: TnfId, properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = TnfToken(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Tnf \(id) unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys
      switch token {
        
      case .depth:      tnfs[id: id]!.depth = property.value.uValue
      case .frequency:  tnfs[id: id]!.frequency = property.value.mhzToHz
      case .permanent:  tnfs[id: id]!.permanent = property.value.bValue
      case .width:      tnfs[id: id]!.width = property.value.mhzToHz
      }
      // is the Tnf initialized?
      if !tnfs[id: id]!.initialized && tnfs[id: id]!.frequency != 0 {
        // YES, notify all observers
        tnfs[id: id]!.initialized = true
        _log("Tnf \(id) added: frequency = \(tnfs[id: id]!.frequency)", .debug, #function, #file, #line)
      }
      updateViewModel()
    }
  }
  
  /// Synchronize the viewModel
  private func updateViewModel() {
    Task {
      ViewModel.shared.tnfs = tnfs
    }
  }
  
  /// Send a command to Set a Tnf property
  /// - Parameters:
  ///   - radio:      a Radio instance
  ///   - id:         the Id for the specified Waterfall
  ///   - token:      the parse token
  ///   - value:      the new value
  private func sendCommand(_ radio: Radio, _ id: TnfId, _ token: TnfToken, _ value: Any) {
    radio.send("tnf set " + "\(id) " + token.rawValue + "=\(value)")
  }
}
