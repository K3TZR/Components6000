//
//  UdpManager.swift
//  CommonCode
//
//  Created by Douglas Adams on 8/15/15.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

import LogProxy
import Shared

///  Stream Manager Class implementation
///      manages all Udp communication with a Radio
final class Stream: NSObject {
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _isRegistered = false
  var _sendIP = ""
  var _sendPort: UInt16 = 4991 // default port number
  let _log = LogProxy.sharedInstance.publish
  let _processQ = DispatchQueue(label: "Stream.processQ", qos: .userInteractive)
  var _socket: GCDAsyncUdpSocket!
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _isBound = false
  private var _receivePort: UInt16 = 0
  private let _receiveQ = DispatchQueue(label: "Stream.ReceiveQ", qos: .userInteractive)
  private let _registerQ = DispatchQueue(label: "Stream.RegisterQ")
  
  private let kPingCmd = "client ping handle"
  private let kPingDelay: UInt32 = 50
  private let kMaxBindAttempts = 20
  private let kRegistrationDelay: UInt32 = 250_000 // (250 microseconds)
    
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Stream Manager
  /// - Parameters:
  ///   - receivePort:            a port number
  init(receivePort: UInt16 = 4991) {
    self._receivePort = receivePort
    
    super.init()
    
    // get an IPV4 socket
    _socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: _receiveQ)
    _socket.setIPv4Enabled(true)
    _socket.setIPv6Enabled(false)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Bind to a UDP Port
  /// - Parameters:
  ///   - selectedRadio:      a DiscoveredPacket
  ///   - clientHandle:       handle
  func bind(_ packet: Packet) -> Bool {
    var success               = false
    var portToUse             : UInt16 = 0
    var tries                 = kMaxBindAttempts
    
    // identify the port
    switch (packet.source, packet.requiresHolePunch) {
      
    case (.smartlink, true):        // isWan w/hole punch
      portToUse = UInt16(packet.negotiatedHolePunchPort)
      _sendPort = UInt16(packet.negotiatedHolePunchPort)
      tries = 1  // isWan w/hole punch
      
    case (.smartlink, false):       // isWan
      portToUse = UInt16(packet.publicUdpPort!)
      _sendPort = UInt16(packet.publicUdpPort!)
      
    default:                  // local
      portToUse = _receivePort
    }
    
    // Find a UDP port to receive on, scan from the default Port Number up looking for an available port
    for _ in 0..<tries {
      do {
        try _socket.bind(toPort: portToUse)
        _log(LogEntry("Stream: bound to port, \(portToUse)", .debug, #function, #file, #line))
        success = true
        
      } catch {
        // We didn't get the port we wanted
        _log(LogEntry("Stream: FAILED to bind to port, \(portToUse)", .debug, #function, #file, #line))
        
        // try the next Port Number
        portToUse += 1
      }
      if success { break }
    }
    
    // was a port bound?
    if success {
      // YES, save the actual port & ip in use
      _receivePort = portToUse
      _sendIP = packet.publicIp
      _isBound = true
      
      // change the state
//      _delegate?.didBind(receivePort: receivePort, sendPort: sendPort)
        // TODO: publish?
      
      // a UDP bind has been established
      beginReceiving()
    }
    return success
  }
  
  /// Begin receiving UDP data
  func beginReceiving() {
    do {
      // Begin receiving
      try _socket.beginReceiving()
      
    } catch let error {
      // read error
      _log(LogEntry("Stream: receiving error, \(error.localizedDescription)", .error, #function, #file, #line))
    }
  }
  
  /// Unbind from the UDP port
  func unbind(reason: String) {
    _isBound = false
    
    // tell the receive socket to close
    _socket.close()
    
    _isRegistered = false
    
    // notify the delegate
    // TODO: publish ???
  }
  
  /// Register UDP client handle
  /// - Parameters:
  ///   - clientHandle:       our client handle
  func register(clientHandle: Handle?) {
    guard clientHandle != nil else {
      // should not happen
      _log(LogEntry("Stream: No client handle in register UDP", .error, #function, #file, #line))
      return
    }
    // register & keep open the router (on a background queue)
    _registerQ.async { [unowned self] in
      while self._socket != nil && !self._isRegistered && self._isBound {
        
        self._log(LogEntry("Stream: register wan, handle=" + clientHandle!.hex, .debug, #function, #file, #line))
        
        // send a Registration command
        let cmd = "client udp_register handle=" + clientHandle!.hex
        self.sendData(cmd.data(using: String.Encoding.ascii, allowLossyConversion: false)!)
        
        // pause
        usleep(self.kRegistrationDelay)
      }
      self._log(LogEntry("Stream: register wan exited, Registration=\(self._isRegistered)", .debug, #function, #file, #line))
    }
  }
}
