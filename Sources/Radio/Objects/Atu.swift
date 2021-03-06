//
//  Atu.swift
//  Components6000/Radio/Objects
//
//  Created by Douglas Adams on 8/15/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

import Shared

/// Atu Class implementation
///
///      creates an Atu instance to be used by a Client to support the
///      processing of the Antenna Tuning Unit (if installed). Atu objects are
///      added, removed and updated by the incoming TCP messages.
///
//public final class Atu: ObservableObject {
public struct Atu {
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public internal(set) var memoriesEnabled = false
  public internal(set) var status = ""       // FIXME: ?????
  public internal(set) var enabled = false
  public internal(set) var usingMemory = false
  
  // ----------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Status: String {
    case none             = "NONE"
    case tuneNotStarted   = "TUNE_NOT_STARTED"
    case tuneInProgress   = "TUNE_IN_PROGRESS"
    case tuneBypass       = "TUNE_BYPASS"           // Success Byp
    case tuneSuccessful   = "TUNE_SUCCESSFUL"       // Success
    case tuneOK           = "TUNE_OK"
    case tuneFailBypass   = "TUNE_FAIL_BYPASS"      // Byp
    case tuneFail         = "TUNE_FAIL"
    case tuneAborted      = "TUNE_ABORTED"
    case tuneManualBypass = "TUNE_MANUAL_BYPASS"    // Byp
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal types
  
  enum AtuTokens: String {
    case status
    case enabled            = "atu_enabled"
    case memoriesEnabled    = "memories_enabled"
    case usingMemory        = "using_mem"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  //  let _log = LogProxy.sharedInstance.log
    
  private let _log: Log = { msg,level,function,file,line in
    NotificationCenter.default.post(name: logEntryNotification, object: LogEntry(msg, level, function, file, line))
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public Command methods
  
  //    public func clear(callback: ReplyHandler? = nil) {
  //        _api.send("atu clear", replyTo: callback)
  //    }
  //    public func start(callback: ReplyHandler? = nil) {
  //        _api.send("atu start", replyTo: callback)
  //    }
  //    public func bypass(callback: ReplyHandler? = nil) {
  //        _api.send("atu bypass", replyTo: callback)
  //    }
  //    public func memories(_ enabled: Bool, callback: ReplyHandler? = nil) {
  //        _api.send("atu set memories_enabled=\(enabled.as1or0)", replyTo: callback)
  //    }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Command methods
  
  //    private func atuCmd(_ token: AtuTokens, _ value: Any) {
  //        _api.send("atu " + token.rawValue + "=\(value)")
  //    }
  //    private func atuSetCmd(_ token: AtuTokens, _ value: Any) {
  //        _api.send("atu set " + token.rawValue + "=\(value)")
  //    }
}

// ----------------------------------------------------------------------------
// MARK: - StaticModel extension

//extension Atu: StaticModel {
extension Atu {
  /// Parse an Atu status message
  /// - Parameter properties:       a KeyValuesArray
  mutating func parseProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = AtuTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Atu, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .enabled:          enabled = property.value.bValue
      case .memoriesEnabled:  memoriesEnabled = property.value.bValue
      case .status:           status = property.value
      case .usingMemory:      usingMemory = property.value.bValue
      }
    }
  }
}
