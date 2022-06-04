//
//  Wan.swift
//  Components6000/Radio/Objects
//
//  Created by Douglas Adams on 8/17/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

import Shared

/// Wan Class implementation
///
///      creates a Wan instance to be used by a Client to support the
///      processing of the Wan-related activities. Wan objects are added,
///      removed and updated by the incoming TCP messages.
///
//public final class Wan : StaticModel {
public struct Wan {

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public internal(set) var radioAuthenticated: Bool = false
  public internal(set) var serverConnected: Bool = false

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  private var _initialized  = false

  enum Token: String {
    case serverConnected    = "server_connected"
    case radioAuthenticated = "radio_authenticated"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  //  let _log = LogProxy.sharedInstance.log
    
  private let _log: Log = { msg,level,function,file,line in
    NotificationCenter.default.post(name: logEntryNotification, object: LogEntry(msg, level, function, file, line))
  }

  // ------------------------------------------------------------------------------
  // MARK: - Instance methods

  /// Parse a Wan status message
  /// - Parameter properties:       a KeyValuesArray
  mutating func parseProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = Token(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Wan: unknown token, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .serverConnected:    serverConnected = property.value.bValue
      case .radioAuthenticated: radioAuthenticated = property.value.bValue 
      }
    }
    // is it initialized?
    if !_initialized {
      // YES, the Radio (hardware) has acknowledged it
      _initialized = true

      // notify all observers
      _log("Wan: status, ServerConnected = \(serverConnected), RadioAuthenticated = \(radioAuthenticated)", .debug, #function, #file, #line)
//      NC.post(.wanHasBeenAdded, object: self as Any?)
    }
  }
}
