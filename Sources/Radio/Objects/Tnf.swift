//
//  Tnf.swift
//  Components6000/Radio/Objects
//
//  Created by Douglas Adams on 6/30/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Foundation
import Shared

/// TNF Class implementation
///
///       creates a Tnf instance to be used by a Client to support the
///       rendering of a Tnf. Tnf objects are added, removed and
///       updated by the incoming TCP messages. They are collected in the
///       tnfs collection on the Radio object.
///

public final class Tnf: Identifiable, ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Static properties

  static let kWidthMin: Hz = 5
  static let kWidthDefault: Hz = 100
  static let kWidthMax: Hz = 6_000

  // ----------------------------------------------------------------------------
  // MARK: - Published properties

  public internal(set) var id: TnfId

  public internal(set) var depth: UInt = 0
  public internal(set) var frequency: Hz = 0
  public internal(set) var permanent = false
  public internal(set) var width: Hz = 0

  // ----------------------------------------------------------------------------
  // MARK: - Public types

  public enum Depth : UInt {
    case normal   = 1
    case deep     = 2
    case veryDeep = 3
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal types

  enum TnfTokens : String {
    case depth
    case frequency = "freq"
    case permanent
    case width
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _initialized = false
  private let _log = LogProxy.sharedInstance.log

  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init(_ id: TnfId) {
    self.id = id
  }
}

// ----------------------------------------------------------------------------
// MARK: - DynamicModel extension

extension Tnf: DynamicModel {
  /// Parse a Tnf status message
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  static func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // Note: Tnf does not send status on removal

    // get the Id
    if let id = properties[0].key.objectId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if Objects.sharedInstance.tnfs[id: id] == nil {

          // NO, create a new Tnf & add it to the Tnfs collection
          Objects.sharedInstance.tnfs[id: id] = Tnf(id)
        }
        // pass the remaining key values to the Tnf for parsing
        Objects.sharedInstance.tnfs[id: id]!.parseProperties(Array(properties.dropFirst(1)) )
      }
    }
  }

  /// Parse Tnf key/value pairs
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValues
  func parseProperties(_ properties: KeyValuesArray) {
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

      case .depth:      depth = property.value.uValue
      case .frequency:  frequency = property.value.mhzToHz
      case .permanent:  permanent = property.value.bValue
      case .width:      width = property.value.mhzToHz
      }
      // is the Tnf initialized?
      if !_initialized && frequency != 0 {
        // YES, the Radio (hardware) has acknowledged this Tnf
        _initialized = true

        // notify all observers
        _log("Tnf, added: id = \(id), frequency = \(frequency)", .debug, #function, #file, #line)
//        NC.post(.tnfHasBeenAdded, object: self as Any?)
      }
    }
  }
}
