//
//  Xvtr.swift
//  Components6000/Radio/Objects
//
//  Created by Douglas Adams on 6/24/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

import Shared

/// Xvtr Class implementation
///
///      creates an Xvtr instance to be used by a Client to support the
///      processing of an Xvtr. Xvtr objects are added, removed and updated by
///      the incoming TCP messages. They are collected in the xvtrs
///      collection on the Radio object.
///
//public final class Xvtr: ObservableObject, Identifiable {
public struct Xvtr: Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public internal(set) var id: XvtrId
  
  public internal(set) var isValid = false
  public internal(set) var preferred = false
  public internal(set) var twoMeterInt = 0
  public internal(set) var ifFrequency: Hz = 0
  public internal(set) var loError = 0
  public internal(set) var name = ""
  public internal(set) var maxPower = 0
  public internal(set) var order = 0
  public internal(set) var rfFrequency: Hz = 0
  public internal(set) var rxGain = 0
  public internal(set) var rxOnly = false
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  enum XvtrTokens : String {
    case name
    case ifFrequency    = "if_freq"
    case isValid        = "is_valid"
    case loError        = "lo_error"
    case maxPower       = "max_power"
    case order
    case preferred
    case rfFrequency    = "rf_freq"
    case rxGain         = "rx_gain"
    case rxOnly         = "rx_only"
    case twoMeterInt    = "two_meter_int"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized = false
  private let _log = LogProxy.sharedInstance.log
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: XvtrId) { self.id = id }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Command methods
  
  //    public func remove(callback: ReplyHandler? = nil) {
  //        _api.send("xvtr remove " + "\(id)", replyTo: callback)
  //    }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Command methods
  
  /// Set an Xvtr property on the Radio
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  //    private func xvtrCmd(_ token: XvtrTokens, _ value: Any) {
  //        _api.send("xvtr set " + "\(id) " + token.rawValue + "=\(value)")
  //    }
}

// ----------------------------------------------------------------------------
// MARK: - DynamicModel extension

//extension Xvtr: DynamicModel {
extension Xvtr {
  /// Parse an Xvtr status message
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
//  class func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true ) {
  static func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true ) {
    // get the id
    if let id = properties[0].key.objectId {
      // isthe Xvtr in use?
      if inUse {
        // YES, does the object exist?
        if Objects.sharedInstance.xvtrs[id: id] == nil {
          // NO, create a new Xvtr & add it to the Xvtrs collection
          Objects.sharedInstance.xvtrs[id: id] = Xvtr(id)
        }
        // pass the remaining key values to the Xvtr for parsing
        Objects.sharedInstance.xvtrs[id: id]!.parseProperties(Array(properties.dropFirst(1)) )
        
      } else {
        // does it exist?
        if Objects.sharedInstance.xvtrs[id: id] != nil {
          // YES, remove it, notify all observers
//          NC.post(.xvtrWillBeRemoved, object: radio.xvtrs[id] as Any?)
          
          Objects.sharedInstance.xvtrs[id: id] = nil
          
          LogProxy.sharedInstance.log("Xvtr, removed: id = \(id)", .debug, #function, #file, #line)
//          NC.post(.xvtrHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }
  
  /// Parse Xvtr key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  mutating func parseProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = XvtrTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Xvtr, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .name:         name = property.value
      case .ifFrequency:  ifFrequency = property.value.mhzToHz
      case .isValid:      isValid = property.value.bValue
      case .loError:      loError = property.value.iValue
      case .maxPower:     maxPower = property.value.iValue
      case .order:        order = property.value.iValue
      case .preferred:    preferred = property.value.bValue
      case .rfFrequency:  rfFrequency = property.value.mhzToHz
      case .rxGain:       rxGain = property.value.iValue
      case .rxOnly:       rxOnly = property.value.bValue
      case .twoMeterInt:  twoMeterInt = property.value.iValue
      }
    }
    // is the waterfall initialized?
    if !_initialized {
      // YES, the Radio (hardware) has acknowledged this Waterfall
      _initialized = true
      
      // notify all observers
      _log("Xvtr, added: id = \(id), name = \(name)", .debug, #function, #file, #line)
//      NC.post(.xvtrHasBeenAdded, object: self as Any?)
    }
  }
}
