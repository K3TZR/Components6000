//
//  Waveform.swift
//  Components6000/Radio/Objects
//
//  Created by Douglas Adams on 8/17/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

import Shared

/// Waveform Class implementation
///
///      creates a Waveform instance to be used by a Client to support the
///      processing of installed Waveform functions. Waveform objects are added,
///      removed and updated by the incoming TCP messages.
///
//public final class Waveform: ObservableObject {
public struct Waveform {
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public internal(set) var waveformList = ""
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal types
  
  enum WaveformTokens: String {
    case waveformList = "installed_list"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  //  let _log = LogProxy.sharedInstance.log
    
  private let _log: Log = { msg,level,function,file,line in
    NotificationCenter.default.post(name: logEntryNotification, object: LogEntry(msg, level, function, file, line))
  }
}

// ----------------------------------------------------------------------------
// MARK: - StaticModel extension

//extension Waveform: StaticModel {
extension Waveform {
  /// Parse a Waveform status message
  ///   format: <key=value> <key=value> ...<key=value>
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  mutating func parseProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = WaveformTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Waveform, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .waveformList: waveformList = property.value
      }
    }
  }
}
