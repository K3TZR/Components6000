//
//  WaterfallCollection.swift
//  
//
//  Created by Douglas Adams on 4/17/22.
//

import Foundation
import IdentifiedCollections

import Shared

@globalActor
public actor WaterfallCollection {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static let shared = WaterfallCollection()
  private init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var waterfalls: IdentifiedArrayOf<Waterfall> = []

  public enum WaterfallToken : String {
     case clientHandle         = "client_handle"   // New Api only
     
     // on Waterfall
     case autoBlackEnabled     = "auto_black"
     case blackLevel           = "black_level"
     case colorGain            = "color_gain"
     case gradientIndex        = "gradient_index"
     case lineDuration         = "line_duration"
     
     // unused here
     case available
     case band
     case bandZoomEnabled      = "band_zoom"
     case bandwidth
     case capacity
     case center
     case daxIq                = "daxiq"
     case daxIqChannel         = "daxiq_channel"
     case daxIqRate            = "daxiq_rate"
     case loopA                = "loopa"
     case loopB                = "loopb"
     case panadapterId         = "panadapter"
     case rfGain               = "rfgain"
     case rxAnt                = "rxant"
     case segmentZoomEnabled   = "segment_zoom"
     case wide
     case xPixels              = "x_pixels"
     case xvtr
   }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log = LogProxy.sharedInstance.log

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Parse a Waterfall status message
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  ///   - inUse:          false = "to be deleted"
  ///
  public func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // get the Id
    if let id = properties[1].key.streamId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if waterfalls[id: id] == nil {
          // Create a Waterfall & add it to the Waterfalls collection
          waterfalls[id: id] = Waterfall(id)
        }
        // pass the key values to the Waterfall for parsing (dropping the Type and Id)
        parseProperties( id, properties: Array(properties.dropFirst(2)))
        
      } else {
        // does it exist?
        if waterfalls[id: id] != nil {
          // YES, remove the Panadapter & Waterfall, notify all observers
          if let panId = Objects.sharedInstance.waterfalls[id: id]!.panadapterId {
            
            Objects.sharedInstance.panadapters[id: panId] = nil
            
            _log("Panadapter \(panId.hex): removed", .debug, #function, #file, #line)
            //            NC.post(.panadapterHasBeenRemoved, object: id as Any?)
            
            //            NC.post(.waterfallWillBeRemoved, object: radio.waterfalls[id] as Any?)
            
            waterfalls[id: id] = nil
            
            _log("Waterfall \(id.hex): removed", .debug, #function, #file, #line)
            //            NC.post(.waterfallHasBeenRemoved, object: id as Any?)
          }
        }
      }
    }
  }
  
  public func setProperty(radio: Radio, _ id: WaterfallId, property: WaterfallToken, value: Any) {
    switch property {
    case .autoBlackEnabled:   sendCommand( radio, id, .autoBlackEnabled, (value as! Bool).as1or0)
    case .blackLevel:         sendCommand( radio, id, .blackLevel, value)
    case .colorGain:          sendCommand( radio, id, .colorGain, value)
    case .gradientIndex:      sendCommand( radio, id, .gradientIndex, value)
    case .lineDuration:       sendCommand( radio, id, .lineDuration, value)
    default:                  break
    }
  }

  public func getProperty( _ id: WaterfallId, property: WaterfallToken) -> Any? {
    switch property {
    case .autoBlackEnabled:   return waterfalls[id: id]?.autoBlackEnabled as Any
    case .blackLevel:         return waterfalls[id: id]?.blackLevel as Any
    case .clientHandle:       return waterfalls[id: id]?.clientHandle as Any
    case .colorGain:          return waterfalls[id: id]?.colorGain as Any
    case .gradientIndex:      return waterfalls[id: id]?.gradientIndex as Any
    case .lineDuration:       return waterfalls[id: id]?.lineDuration as Any
    case .panadapterId:       return waterfalls[id: id]!.panadapterId as Any
      // the following are ignored here
    case .available, .band, .bandwidth, .bandZoomEnabled, .capacity, .center, .daxIq, .daxIqChannel,
        .daxIqRate, .loopA, .loopB, .rfGain, .rxAnt, .segmentZoomEnabled, .wide, .xPixels, .xvtr:  return nil
    }
  }

  /// Remove the specified Waterfall
  /// - Parameter id:     a TnfId
  public func remove(_ id: WaterfallId) {
    waterfalls.remove(id: id)
    updateViewModel()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse Waterfall key/value pairs
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - id:               the id of the Waterfall
  ///   - properties:       a KeyValuesArray of Waterfall properties
  ///
  private func parseProperties(_ id: WaterfallId, properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = WaterfallToken(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Waterfall \(id.hex) unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .autoBlackEnabled:   waterfalls[id: id]!.autoBlackEnabled = property.value.bValue
      case .blackLevel:         waterfalls[id: id]!.blackLevel = property.value.iValue
      case .clientHandle:       waterfalls[id: id]!.clientHandle = property.value.handle ?? 0
      case .colorGain:          waterfalls[id: id]!.colorGain = property.value.iValue
      case .gradientIndex:      waterfalls[id: id]!.gradientIndex = property.value.iValue
      case .lineDuration:       waterfalls[id: id]!.lineDuration = property.value.iValue
      case .panadapterId:       waterfalls[id: id]!.panadapterId = property.value.streamId ?? 0
        // the following are ignored here
      case .available, .band, .bandwidth, .bandZoomEnabled, .capacity, .center, .daxIq, .daxIqChannel,
          .daxIqRate, .loopA, .loopB, .rfGain, .rxAnt, .segmentZoomEnabled, .wide, .xPixels, .xvtr:  break
      }
    }
    // is the waterfall initialized?
    if !waterfalls[id: id]!.initialized && waterfalls[id: id]!.panadapterId != 0 {
      // YES, the Radio (hardware) has acknowledged this Waterfall
      waterfalls[id: id]!.initialized = true
      
      // notify all observers
      _log("Waterfall \(id.hex) added: handle = \(waterfalls[id: id]!.clientHandle.hex)", .debug, #function, #file, #line)
    }
    updateViewModel()
  }
    
  /// Synchronize the viewModel
  private func updateViewModel() {
    Task {
      ViewModel.shared.waterfalls = waterfalls
    }
  }
  
  /// Send a command to Set a Waterfall property
  /// - Parameters:
  ///   - radio:      a Radio instance
  ///   - id:         the Id for the specified Waterfall
  ///   - token:      the parse token
  ///   - value:      the new value
  private func sendCommand(_ radio: Radio, _ id: WaterfallId, _ token: WaterfallToken, _ value: Any) {
      radio.send("display panafall set " + "\(id.hex) " + token.rawValue + "=\(value)")
  }

}
