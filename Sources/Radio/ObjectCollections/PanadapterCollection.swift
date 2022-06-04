//
//  PanadapterCollection.swift
//  
//
//  Created by Douglas Adams on 4/17/22.
//

import Foundation
import IdentifiedCollections

import Shared

@globalActor
public actor PanadapterCollection {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static let shared = PanadapterCollection()
  private init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var panadapters: IdentifiedArrayOf<Panadapter> = []

  public enum PanadapterToken : String {
    // on Panadapter
    case antList                    = "ant_list"
    case average
    case band
    case bandwidth
    case bandZoomEnabled            = "band_zoom"
    case center
    case clientHandle               = "client_handle"
    case daxIq                      = "daxiq"
    case daxIqChannel               = "daxiq_channel"
    case fps
    case loopAEnabled               = "loopa"
    case loopBEnabled               = "loopb"
    case maxBw                      = "max_bw"
    case maxDbm                     = "max_dbm"
    case minBw                      = "min_bw"
    case minDbm                     = "min_dbm"
    case preamp                     = "pre"
    case rfGain                     = "rfgain"
    case rxAnt                      = "rxant"
    case segmentZoomEnabled         = "segment_zoom"
    case waterfallId                = "waterfall"
    case weightedAverageEnabled     = "weighted_average"
    case wide
    case wnbEnabled                 = "wnb"
    case wnbLevel                   = "wnb_level"
    case wnbUpdating                = "wnb_updating"
    case xPixels                    = "x_pixels"
    case xvtrLabel                  = "xvtr"
    case yPixels                    = "y_pixels"
    // ignored by Panadapter
    case available
    case capacity
    case daxIqRate                  = "daxiq_rate"
    // not sent in status messages
    case n1mmSpectrumEnable         = "n1mm_spectrum_enable"
    case n1mmAddress                = "n1mm_address"
    case n1mmPort                   = "n1mm_port"
    case n1mmRadio                  = "n1mm_radio"
  }
  
  public struct LegendValue: Identifiable {
    public var id: CGFloat         // relative position 0...1
    public var label: String       // value to display
    public var value: CGFloat      // actual value
    public var lineCount: CGFloat
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  //  let _log = LogProxy.sharedInstance.log
    
  private let _log: Log = { msg,level,function,file,line in
    NotificationCenter.default.post(name: logEntryNotification, object: LogEntry(msg, level, function, file, line))
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Parse a Panadapter status message
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  ///   - inUse:          false = "to be deleted"
  func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    //get the Id
    if let id =  properties[1].key.streamId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if panadapters[id: id] == nil {
          // create a new object & add it to the collection
          panadapters[id: id] = Panadapter(id)
        }
        // pass the remaining key values for parsing
        parseProperties(id, properties: Array(properties.dropFirst(2)) )
        
      } else {
        // NO, does it exist?
        if panadapters[id: id] != nil {
          // YES, notify all observers
          //          NC.post(.panadapterWillBeRemoved, object: self as Any?)
        }
      }
    }
    //        }
  }

  public func setProperty(radio: Radio, _ id: PanadapterId, _ property: PanadapterToken, _ value: Any) {
    switch property {
    case .antList:                sendCommand( radio, id, .antList, value)
    case .average:                sendCommand( radio, id, .average, value)
    case .band:                   sendCommand( radio, id, .band, value)
    case .bandwidth:              sendCommand( radio, id, .bandwidth, (value as! Hz).hzToMhz)
    case .bandZoomEnabled:        sendCommand( radio, id, .bandZoomEnabled, (value as! Bool).as1or0)
    case .center:                 sendCommand( radio, id, .center, (value as! Hz).hzToMhz)
    case .clientHandle:           sendCommand( radio, id, .clientHandle, value)
    case .daxIq:                  sendCommand( radio, id, .daxIqChannel, value)
    case .daxIqChannel:           sendCommand( radio, id, .daxIqChannel, value)
    case .fps:                    sendCommand( radio, id, .fps, value)
    case .loopAEnabled:           sendCommand( radio, id, .loopAEnabled, (value as! Bool).as1or0)
    case .loopBEnabled:           sendCommand( radio, id, .loopBEnabled, (value as! Bool).as1or0)
    case .maxBw:                  sendCommand( radio, id, .maxBw, (value as! Hz).hzToMhz)
    case .maxDbm:                 sendCommand( radio, id, .maxDbm, value)
    case .minBw:                  sendCommand( radio, id, .minBw, (value as! Hz).hzToMhz)
    case .minDbm:                 sendCommand( radio, id, .minDbm, value)
    case .preamp:                 sendCommand( radio, id, .preamp, value)
    case .rfGain:                 sendCommand( radio, id, .rfGain, value)
    case .rxAnt:                  sendCommand( radio, id, .rxAnt, value)
    case .segmentZoomEnabled:     sendCommand( radio, id, .segmentZoomEnabled, (value as! Bool).as1or0)
    case .waterfallId:            sendCommand( radio, id, .waterfallId, value)
    case .wide:                   sendCommand( radio, id, .wide, (value as! Bool).as1or0)
    case .weightedAverageEnabled: sendCommand( radio, id, .weightedAverageEnabled, (value as! Bool).as1or0)
    case .wnbEnabled:             sendCommand( radio, id, .wnbEnabled, (value as! Bool).as1or0)
    case .wnbLevel:               sendCommand( radio, id, .wnbLevel, value)
    case .wnbUpdating:            sendCommand( radio, id, .wnbUpdating, (value as! Bool).as1or0)
    case .xPixels:                sendCommand( radio, id, "xpixels", value)
    case .xvtrLabel:              sendCommand( radio, id, .xvtrLabel, value)
    case .yPixels:                sendCommand( radio, id, "ypixels", value)
    
    case .available, .capacity, .daxIqRate:                         break // ignored by Panadapter
    case .n1mmSpectrumEnable, .n1mmAddress, .n1mmPort, .n1mmRadio:  break // not sent in status messages
    }
  }

//  public func getProperty( _ id: PanadapterId, _ property: PanadapterToken) -> Any? {
//    switch property {
//    case .antList:                return panadapters[id: id]?.antList as Any
//    case .average:                return panadapters[id: id]?.average as Any
//    case .band:                   return panadapters[id: id]?.band as Any
//    case .bandwidth:              return panadapters[id: id]?.bandwidth as Any
//    case .bandZoomEnabled:        return panadapters[id: id]?.bandZoomEnabled as Any
//    case .center:                 return panadapters[id: id]?.center as Any
//    case .clientHandle:           return panadapters[id: id]?.clientHandle as Any
//    case .daxIq:                  return panadapters[id: id]?.daxIqChannel as Any
//    case .daxIqChannel:           return panadapters[id: id]?.daxIqChannel as Any
//    case .fps:                    return panadapters[id: id]?.fps as Any
//    case .loopAEnabled:           return panadapters[id: id]?.loopAEnabled as Any
//    case .loopBEnabled:           return panadapters[id: id]?.loopBEnabled as Any
//    case .maxBw:                  return panadapters[id: id]?.maxBw as Any
//    case .maxDbm:                 return panadapters[id: id]?.maxDbm as Any
//    case .minBw:                  return panadapters[id: id]?.minBw as Any
//    case .minDbm:                 return panadapters[id: id]?.minDbm as Any
//    case .preamp:                 return panadapters[id: id]?.preamp as Any
//    case .rfGain:                 return panadapters[id: id]?.rfGain as Any
//    case .rxAnt:                  return panadapters[id: id]?.rxAnt as Any
//    case .segmentZoomEnabled:     return panadapters[id: id]?.segmentZoomEnabled as Any
//    case .waterfallId:            return panadapters[id: id]?.waterfallId as Any
//    case .wide:                   return panadapters[id: id]?.wide as Any
//    case .weightedAverageEnabled: return panadapters[id: id]?.weightedAverageEnabled as Any
//    case .wnbEnabled:             return panadapters[id: id]?.wnbEnabled as Any
//    case .wnbLevel:               return panadapters[id: id]?.wnbLevel as Any
//    case .wnbUpdating:            return panadapters[id: id]?.wnbUpdating as Any
//    case .xvtrLabel:              return panadapters[id: id]?.xvtrLabel as Any
//    
//    case .available, .capacity, .daxIqRate, .xPixels, .yPixels:     return nil // ignored by Panadapter
//    case .n1mmSpectrumEnable, .n1mmAddress, .n1mmPort, .n1mmRadio:  return nil // not sent in status messages
//    }
//  }

  /// Remove the specified Panadapter
  /// - Parameter id:     a TnfId
  public func remove(_ id: PanadapterId) {
    panadapters.remove(id: id)
    updateViewModel()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse Panadapter key/value pairs
  /// - Parameters:
  ///   - id:                   the id of the Tnf
  ///   - properties:           a KeyValuesArray of Panadapter properties
  private func parseProperties(_ id: PanadapterId, properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = PanadapterToken(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Panadapter \(id.hex) unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
      case .antList:                panadapters[id: id]!.antList = property.value.list
      case .average:                panadapters[id: id]!.average = property.value.iValue
      case .band:                   panadapters[id: id]!.band = property.value
      case .bandwidth:              panadapters[id: id]!.bandwidth = property.value.mhzToHz
                                    panadapters[id: id]!.freqValues = panadapters[id: id]!.calcFreqValues()
      case .bandZoomEnabled:        panadapters[id: id]!.bandZoomEnabled = property.value.bValue
      case .center:                 panadapters[id: id]!.center = property.value.mhzToHz
                                    panadapters[id: id]!.dbmValues = panadapters[id: id]!.calcDbmValues()
                                    panadapters[id: id]!.freqValues = panadapters[id: id]!.calcFreqValues()
      case .clientHandle:           panadapters[id: id]!.clientHandle = property.value.handle ?? 0
      case .daxIq:                  panadapters[id: id]!.daxIqChannel = property.value.iValue
      case .daxIqChannel:           panadapters[id: id]!.daxIqChannel = property.value.iValue
      case .fps:                    panadapters[id: id]!.fps = property.value.iValue
      case .loopAEnabled:           panadapters[id: id]!.loopAEnabled = property.value.bValue
      case .loopBEnabled:           panadapters[id: id]!.loopBEnabled = property.value.bValue
      case .maxBw:                  panadapters[id: id]!.maxBw = property.value.mhzToHz
      case .maxDbm:                 panadapters[id: id]!.maxDbm = property.value.cgValue
      case .minBw:                  panadapters[id: id]!.minBw = property.value.mhzToHz
      case .minDbm:                 panadapters[id: id]!.minDbm = property.value.cgValue
      case .preamp:                 panadapters[id: id]!.preamp = property.value
      case .rfGain:                 panadapters[id: id]!.rfGain = property.value.iValue
      case .rxAnt:                  panadapters[id: id]!.rxAnt = property.value
      case .segmentZoomEnabled:     panadapters[id: id]!.segmentZoomEnabled = property.value.bValue
      case .waterfallId:            panadapters[id: id]!.waterfallId = property.value.streamId ?? 0
      case .wide:                   panadapters[id: id]!.wide = property.value.bValue
      case .weightedAverageEnabled: panadapters[id: id]!.weightedAverageEnabled = property.value.bValue
      case .wnbEnabled:             panadapters[id: id]!.wnbEnabled = property.value.bValue
      case .wnbLevel:               panadapters[id: id]!.wnbLevel = property.value.iValue
      case .wnbUpdating:            panadapters[id: id]!.wnbUpdating = property.value.bValue
      case .xvtrLabel:              panadapters[id: id]!.xvtrLabel = property.value
      
      case .available, .capacity, .daxIqRate, .xPixels, .yPixels:     break // ignored by Panadapter
      case .n1mmSpectrumEnable, .n1mmAddress, .n1mmPort, .n1mmRadio:  break // not sent in status messages
      }
    }
    // is the Panadapter initialized?∫
    if !panadapters[id: id]!.initialized && panadapters[id: id]!.center != 0 && panadapters[id: id]!.bandwidth != 0 && (panadapters[id: id]!.minDbm != 0.0 || panadapters[id: id]!.maxDbm != 0.0) {
      // YES, the Radio (hardware) has acknowledged this Panadapter
      panadapters[id: id]!.initialized = true
      
      // notify all observers
      _log("Panadapter \(id.hex) added: center = \(panadapters[id: id]!.center.hzToMhz), bandwidth = \(panadapters[id: id]!.bandwidth.hzToMhz)", .debug, #function, #file, #line)
    }
    updateViewModel()
  }

  /// Synchronize the viewModel
  private func updateViewModel() {
    Task {
      ViewModel.shared.panadapters = panadapters
    }
  }

  /// Send a command to Set a Panadapter property
  /// - Parameters:
  ///   - radio:      a Radio instance
  ///   - id:         the Id for the specified Waterfall
  ///   - token:      the parse token
  ///   - value:      the new value
  private func sendCommand(_ radio: Radio, _ id: PanadapterId, _ token: PanadapterToken, _ value: Any) {
      radio.send("display panafall set " + "\(id.hex) " + token.rawValue + "=\(value)")
  }

  /// Send a command to Set a Panadapter property
  /// - Parameters:
  ///   - radio:      a Radio instance
  ///   - id:         the Id for the specified Waterfall
  ///   - token:      a String used as the token
  ///   - value:      the new value
  private func sendCommand(_ radio: Radio, _ id: PanadapterId, _ token: String, _ value: Any) {
      // NOTE: commands use this format when the Token received does not match the Token sent
      //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
      radio.send("display panafall set " + "\(id.hex) " + token + "=\(value)")
  }
}
