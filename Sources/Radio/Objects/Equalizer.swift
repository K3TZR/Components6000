//
//  Equalizer.swift
//  xLib6001
//
//  Created by Douglas Adams on 5/31/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation
import Shared

/// Equalizer Class implementation
///
///      creates an Equalizer instance to be used by a Client to support the
///      rendering of an Equalizer. Equalizer objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the equalizers
///      collection on the Radio object.
///
///      Note: ignores the non-"sc" version of Equalizer messages
///            The "sc" version is the standard for API Version 1.4 and greater
///

public final class Equalizer: ObservableObject, Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Published properties

  @Published public internal(set) var id: EqualizerId

  @Published public var eqEnabled = false
  @Published public var level63Hz = 0
  @Published public var level125Hz = 0
  @Published public var level250Hz = 0
  @Published public var level500Hz = 0
  @Published public var level1000Hz = 0
  @Published public var level2000Hz = 0
  @Published public var level4000Hz = 0
  @Published public var level8000Hz = 0

  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public enum EqType: String {
    case rx      // deprecated type
    case rxsc
    case tx      // deprecated type
    case txsc
  }

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties

  enum EqualizerTokens: String {
    case level63Hz                          = "63hz"
    case level125Hz                         = "125hz"
    case level250Hz                         = "250hz"
    case level500Hz                         = "500hz"
    case level1000Hz                        = "1000hz"
    case level2000Hz                        = "2000hz"
    case level4000Hz                        = "4000hz"
    case level8000Hz                        = "8000hz"
    case enabled                            = "mode"
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties

  private var _initialized = false
  private let _log = LogProxy.sharedInstance.log
  private var _suppress = false

  // ------------------------------------------------------------------------------
  // MARK: - Initialization

  public init(_ id: EqualizerId) { self.id = id }
}

// ----------------------------------------------------------------------------
// MARK: - DynamicModel extension

extension Equalizer: DynamicModel {
  /// Parse a Stream status message
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    var equalizer: Equalizer?

    // get the Type
    let type = properties[0].key

    // determine the type of Equalizer
    switch type {

    case EqType.txsc.rawValue:  equalizer = radio.equalizers[.txsc]
    case EqType.rxsc.rawValue:  equalizer = radio.equalizers[.rxsc]
    case EqType.rx.rawValue, EqType.tx.rawValue:  break // obslete types, ignore
    default: LogProxy.sharedInstance.log("Radio: Unknown Equalizer type: \(type)", .warning, #function, #file, #line)
    }
    // if an equalizer was found
    if let equalizer = equalizer {
      // pass the key values to the Equalizer for parsing (dropping the Type)
      equalizer.parseProperties(radio, Array(properties.dropFirst(1)) )
    }
  }

  /// Parse Equalizer key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = EqualizerTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Radio: Equalizer, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known Keys, in alphabetical order
      switch token {

      case .level63Hz:    level63Hz = property.value.iValue
      case .level125Hz:   level125Hz = property.value.iValue
      case .level250Hz:   level250Hz = property.value.iValue
      case .level500Hz:   level500Hz = property.value.iValue
      case .level1000Hz:  level1000Hz = property.value.iValue
      case .level2000Hz:  level2000Hz = property.value.iValue
      case .level4000Hz:  level4000Hz = property.value.iValue
      case .level8000Hz:  level8000Hz = property.value.iValue
      case .enabled:      eqEnabled = property.value.bValue
      }
    }
    // is the Equalizer initialized?
    if !_initialized {
      // NO, the Radio (hardware) has acknowledged this Equalizer
      _initialized = true

      // notify all observers
      _log("Radio: Equalizer added: id = \(id)", .debug, #function, #file, #line)
//      NC.post(.equalizerHasBeenAdded, object: self as Any?)
    }
  }
}
