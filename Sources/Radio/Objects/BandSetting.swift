//
//  BandSetting.swift
//  Components6000/Radio/Objects
//
//  Created by Douglas Adams on 4/6/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Foundation
import Shared

/// BandSetting Class implementation
///
///      creates a BandSetting instance to be used by a Client to support the
///      processing of the band settings. BandSetting objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the bandSettings
///      collection on the Radio object.
///
public final class BandSetting: ObservableObject, Identifiable {
  // ------------------------------------------------------------------------------
  // MARK: - Published properties

  @Published public internal(set) var id: BandId

  @Published public var accTxEnabled = false
  @Published public var accTxReqEnabled = false
  @Published public var bandName = ""
  @Published public var hwAlcEnabled = false
  @Published public var inhibit = false
  @Published public var rcaTxReqEnabled = false
  @Published public var rfPower = 0
  @Published public var tunePower = 0
  @Published public var tx1Enabled = false
  @Published public var tx2Enabled = false
  @Published public var tx3Enabled = false

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties

  enum BandSettingTokens: String {
    case accTxEnabled       = "acc_tx_enabled"
    case accTxReqEnabled    = "acc_txreq_enable"
    case bandName           = "band_name"
    case hwAlcEnabled       = "hwalc_enabled"
    case inhibit
    case rcaTxReqEnabled    = "rca_txreq_enable"
    case rfPower            = "rfpower"
    case tunePower          = "tunepower"
    case tx1Enabled         = "tx1_enabled"
    case tx2Enabled         = "tx2_enabled"
    case tx3Enabled         = "tx3_enabled"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _initialized = false
  private let _log = LogProxy.sharedInstance.log

  // ------------------------------------------------------------------------------
  // MARK: - Initialization

  public init(_ id: BandId) { self.id = id }
}

// ----------------------------------------------------------------------------
// MARK: - DynamicModel extension

extension BandSetting: DynamicModel {
  /// Parse a BandSetting status message
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // get the Id
    if let id = properties[0].key.objectId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if Objects.sharedInstance.bandSettings[id: id] == nil {
          // NO, create a new BandSetting & add it to the BandSettings collection
          Objects.sharedInstance.bandSettings[id: id] = BandSetting(id)
        }
        // pass the remaining key values to the BandSetting for parsing
        Objects.sharedInstance.bandSettings[id: id]!.parseProperties(Array(properties.dropFirst(1)) )

      } else {
        // does it exist?
        if Objects.sharedInstance.bandSettings[id: id] != nil {
          // YES, remove it, notify observers
//          NC.post(.bandSettingWillBeRemoved, object: radio.bandSettings[id] as Any?)

          Objects.sharedInstance.bandSettings[id: id] = nil

          LogProxy.sharedInstance.log("BandSetting removed: id = \(id)", .debug, #function, #file, #line)
//          NC.post(.bandSettingHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }

  /// Parse BandSetting key/value pairs
  ///   PropertiesParser Protocol method, , executes on the parseQ
  /// - Parameter properties:       a KeyValuesArray
  func parseProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = BandSettingTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("BandSetting, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {

      case .accTxEnabled:     accTxEnabled = property.value.bValue
      case .accTxReqEnabled:  accTxReqEnabled = property.value.bValue
      case .bandName:         bandName = property.value
      case .hwAlcEnabled:     hwAlcEnabled = property.value.bValue
      case .inhibit:          inhibit = property.value.bValue
      case .rcaTxReqEnabled:  rcaTxReqEnabled = property.value.bValue
      case .rfPower:          rfPower = property.value.iValue
      case .tunePower:        tunePower = property.value.iValue
      case .tx1Enabled:       tx1Enabled = property.value.bValue
      case .tx2Enabled:       tx2Enabled = property.value.bValue
      case .tx3Enabled:       tx3Enabled = property.value.bValue
      }
    }
    // is the BandSetting initialized?
    if _initialized == false {
      // YES, the Radio (hardware) has acknowledged this BandSetting
      _initialized = true

      // notify all observers
      _log("BandSetting, added: id = \(id), bandName = \(bandName)", .debug, #function, #file, #line)
//      NC.post(.bandSettingHasBeenAdded, object: self as Any?)
    }
  }
}
