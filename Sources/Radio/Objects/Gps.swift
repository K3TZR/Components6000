//
//  Gps.swift
//  Components6000/Radio/Objects
//
//  Created by Douglas Adams on 8/15/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

import Shared

/// Gps Class implementation
///
///      creates a Gps instance to be used by a Client to support the
///      processing of the internal Gps (if installed). Gps objects are added,
///      removed and updated by the incoming TCP messages.
///
//public final class Gps: ObservableObject {
public struct Gps {
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kGpsCmd = "radio gps "
  
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public internal(set) var altitude = ""
  public internal(set) var frequencyError: Double = 0
  public internal(set) var grid = ""
  public internal(set) var latitude = ""
  public internal(set) var longitude = ""
  public internal(set) var speed = ""
  public internal(set) var status = false
  public internal(set) var time = ""
  public internal(set) var track: Double = 0
  public internal(set) var tracked = false
  public internal(set) var visible = false
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal types
  
  enum GpsTokens: String {
    case altitude
    case frequencyError = "freq_error"
    case grid
    case latitude = "lat"
    case longitude = "lon"
    case speed
    case status
    case time
    case track
    case tracked
    case visible
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  //  let _log = LogProxy.sharedInstance.log
    
  private let _log: Log = { msg,level,function,file,line in
    NotificationCenter.default.post(name: logEntryNotification, object: LogEntry(msg, level, function, file, line))
  }

  // ----------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Gps Install
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  //    public class func gpsInstall(callback: ReplyHandler? = nil) {
  //        Api.sharedInstance.send(kGpsCmd + "install", replyTo: callback)
  //    }
  //
  //    /// Gps Un-Install
  //    /// - Parameters:
  //    ///   - callback:           ReplyHandler (optional)
  //    ///
  //    public class func gpsUnInstall(callback: ReplyHandler? = nil) {
  //        Api.sharedInstance.send(kGpsCmd + "uninstall", replyTo: callback)
  //    }
}

// ----------------------------------------------------------------------------
// MARK: - StaticModel extension

//extension Gps: StaticModel {
extension Gps {
  /// Parse a Gps status message
  /// - Parameter properties:       a KeyValuesArray
  mutating func parseProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = GpsTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Gps, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
      case .altitude:       altitude = property.value
      case .frequencyError: frequencyError = property.value.dValue
      case .grid:           grid = property.value
      case .latitude:       latitude = property.value
      case .longitude:      longitude = property.value
      case .speed:          speed = property.value
      case .status:         status = property.value == "present" ? true : false
      case .time:           time = property.value
      case .track:          track = property.value.dValue
      case .tracked:        tracked = property.value.bValue
      case .visible:        visible = property.value.bValue 
      }
    }
  }
}
