//
//  DaxMicAudioStream.swift
//  Components6000/Radio/Objects
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

import Shared

/// DaxMicAudioStream Class implementation
///
///      creates a DaxMicAudioStream instance to be used by a Client to support the
///      processing of a stream of Mic Audio from the Radio to the client. DaxMicAudioStream
///      objects are added / removed by the incoming TCP messages. DaxMicAudioStream
///      objects periodically receive Mic Audio in a UDP stream. They are collected
///      in the daxMicAudioStreams collection on the Radio object.
///
//public final class DaxMicAudioStream: ObservableObject, Identifiable {
public struct DaxMicAudioStream: Identifiable {
  // ------------------------------------------------------------------------------
  // MARK: - Published properties
  
  public internal(set) var id: DaxMicStreamId
  
  public internal(set) var clientHandle: Handle = 0
  public internal(set) var ip = ""
  var _isStreaming = false
  public internal(set) var micGain = 0 {
    didSet { if micGain != oldValue {
      var newGain = micGain
      // check limits
      if newGain > 100 { newGain = 100 }
      if newGain < 0 { newGain = 0 }
      if micGain != newGain {
        micGain = newGain
        if micGain == 0 {
          micGainScalar = 0.0
          return
        }
        let db_min:Float = -10.0;
        let db_max:Float = +10.0;
        let db:Float = db_min + (Float(micGain) / 100.0) * (db_max - db_min);
        micGainScalar = pow(10.0, db / 20.0);
      }
    }}}
  public internal(set) var micGainScalar: Float = 0
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var delegate: StreamHandler?
  public var rxLostPacketCount = 0
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  enum DaxMicTokens: String {
    case clientHandle           = "client_handle"
    case ip
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized = false
  //  let _log = LogProxy.sharedInstance.log
    
  private let _log: Log = { msg,level,function,file,line in
    NotificationCenter.default.post(name: logEntryNotification, object: LogEntry(msg, level, function, file, line))
  }
  private var _rxPacketCount = 0
  private var _rxLostPacketCount = 0
  private var _rxSequenceNumber = -1
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: DaxMicStreamId) { self.id = id }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Command methods
  
  //    public func remove(callback: ReplyHandler? = nil) {
  //        _api.send("stream remove \(id.hex)", replyTo: callback)
  //
  //        // notify all observers
  //        NC.post(.daxMicAudioStreamWillBeRemoved, object: self as Any?)
  //    }
}

// ----------------------------------------------------------------------------
// MARK: - DynamicModelWithStream extension

//extension DaxMicAudioStream: DynamicModelWithStream {
extension DaxMicAudioStream {
  /// Parse a DAX Mic AudioStream status message
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
//  class func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
  static func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // get the Id
    if let id =  properties[0].key.streamId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if Objects.sharedInstance.daxMicAudioStreams[id: id] == nil {
          // NO, create a new object & add it to the collection
          Objects.sharedInstance.daxMicAudioStreams[id: id] = DaxMicAudioStream(id)
        }
        // pass the remaining key values for parsing
        Objects.sharedInstance.daxMicAudioStreams[id: id]!.parseProperties(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, does it exist?
        if Objects.sharedInstance.daxMicAudioStreams[id: id] != nil {
          // YES, remove it
          Objects.sharedInstance.daxMicAudioStreams[id: id] = nil
          
//          LogProxy.sharedInstance.log("DaxMicAudioStream removed: id = \(id.hex)", .debug, #function, #file, #line)
          NotificationCenter.default.post(name: logEntryNotification, object: LogEntry("DaxMicAudioStream removed: id = \(id.hex)", .debug, #function, #file, #line))
        }
      }
    }
  }
  
  /// Parse Mic Audio Stream key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  mutating func parseProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown keys
      guard let token = DaxMicTokens(rawValue: property.key) else {
        // unknown Key, log it and ignore the Key
        _log("DaxMicAudioStream, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle: clientHandle = property.value.handle ?? 0
      case .ip:           ip = property.value
      case .type:         break  // included to inhibit unknown token warnings
      }
    }
    // is the AudioStream acknowledged by the radio?
    if _initialized == false && clientHandle != 0 {
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      // notify all observers
      _log("DaxMicAudioStream, added: id = \(id.hex), handle = \(clientHandle.hex)", .debug, #function, #file, #line)
      //            NC.post(.daxMicAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  
  /// Process the Mic Audio Stream Vita struct
  /// - Parameters:
  ///   - vitaPacket:         a Vita struct
  mutating func vitaProcessor(_ vita: Vita) {
    if _isStreaming == false {
      _isStreaming = true
      // log the start of the stream
      _log("DaxMicAudio Stream started: \(id.hex)", .info, #function, #file, #line)
    }
    // is this the first packet?
    if _rxSequenceNumber == -1 {
      _rxSequenceNumber = vita.sequence
      _rxPacketCount = 1
      _rxLostPacketCount = 0
    } else {
      _rxPacketCount += 1
    }
    
    switch (_rxSequenceNumber, vita.sequence) {
      
    case (let expected, let received) where received < expected:
      // from a previous group, ignore it
      _log("DaxMicAudioStream delayed frame(s) ignored: expected \(expected), received \(received)", .warning, #function, #file, #line)
      return
      
    case (let expected, let received) where received > expected:
      _rxLostPacketCount += 1
      
      // from a later group, jump forward
      let lossPercent = String(format: "%04.2f", (Float(_rxLostPacketCount)/Float(_rxPacketCount)) * 100.0 )
      _log("DaxMicAudioStream missing frame(s) skipped: expected \(expected), received \(received), loss = \(lossPercent) %", .warning, #function, #file, #line)
      
      _rxSequenceNumber = received
      fallthrough
      
    default:
      // received == expected
      // calculate the next Sequence Number
      _rxSequenceNumber = (_rxSequenceNumber + 1) % 16
      
      if vita.classCode == .daxReducedBw {
        delegate?.streamHandler( DaxRxReducedAudioFrame(payload: vita.payloadData, numberOfSamples: vita.payloadSize / 2 ))
        
      } else {
        delegate?.streamHandler( DaxRxAudioFrame(payload: vita.payloadData, numberOfSamples: vita.payloadSize / (4 * 2) ))
      }
    }
  }
}
