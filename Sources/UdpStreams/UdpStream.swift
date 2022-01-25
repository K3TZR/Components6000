//
//  UdpStream.swift
//  CommonCode
//
//  Created by Douglas Adams on 8/15/15.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import Combine

import Shared

public struct UdpStatus: Identifiable, Equatable {
  public static func == (lhs: UdpStatus, rhs: UdpStatus) -> Bool {
    lhs.id == rhs.id
  }
  
  public var id = UUID()
  var error: Error?
  var host = ""
  var isBound = false
  var port: UInt16 = 0
}

///  UDP Stream Class implementation
///      manages all Udp communication with a Radio
final public class UdpStream: NSObject {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var statusPublisher = PassthroughSubject<UdpStatus, Never>()
  public var streamPublisher = PassthroughSubject<Vita, Never>()

  public var sendIp = ""
  public var sendPort: UInt16 = 4991 // default port number

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _isRegistered = false
  let _log = LogProxy.sharedInstance.log
  let _processQ = DispatchQueue(label: "Stream.processQ", qos: .userInteractive)
  var _socket: GCDAsyncUdpSocket!
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _isBound = false
  private var _receivePort: UInt16 = 0
  private let _receiveQ = DispatchQueue(label: "UdpStream.ReceiveQ", qos: .userInteractive)
  private let _registerQ = DispatchQueue(label: "UdpStream.RegisterQ")
  
  private let kMaxBindAttempts = 20
  private let kPingCmd = "client ping handle"
  private let kPingDelay: UInt32 = 50
  private let kRegistrationDelay: UInt32 = 250_000 // (250 microseconds)
    
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Stream Manager
  /// - Parameters:
  ///   - receivePort:            a port number
  public init(receivePort: UInt16 = 4991) {
    self._receivePort = receivePort
    
    super.init()
    
    // get an IPV4 socket
    _socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: _receiveQ)
    _socket.setIPv4Enabled(true)
    _socket.setIPv6Enabled(false)

    _log("UdpStream: socket initialized", .debug, #function, #file, #line)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Bind to a UDP Port
  /// - Parameters:
  ///   - selectedRadio:      a DiscoveredPacket
  ///   - clientHandle:       handle
  public func bind(_ packet: Packet) -> Bool {
    var success               = false
    var portToUse             : UInt16 = 0
    var tries                 = kMaxBindAttempts
    
    // identify the port
    switch (packet.source, packet.requiresHolePunch) {
      
    case (.smartlink, true):        // isWan w/hole punch
      portToUse = UInt16(packet.negotiatedHolePunchPort)
      sendPort = UInt16(packet.negotiatedHolePunchPort)
      tries = 1  // isWan w/hole punch
      
    case (.smartlink, false):       // isWan
      portToUse = UInt16(packet.publicUdpPort!)
      sendPort = UInt16(packet.publicUdpPort!)
      
    default:                  // local
      portToUse = _receivePort
    }
    
    // Find a UDP port to receive on, scan from the default Port Number up looking for an available port
    for _ in 0..<tries {
      do {
        try _socket.bind(toPort: portToUse)
        _log("UdpStream: bound to port, \(portToUse)", .debug, #function, #file, #line)
        success = true
        
      } catch {
        // We didn't get the port we wanted
        _log("UdpStream: FAILED to bind to port, \(portToUse)", .debug, #function, #file, #line)
        
        // try the next Port Number
        portToUse += 1
      }
      if success { break }
    }
    
    // was a port bound?
    if success {
      // YES, save the actual port & ip in use
      _receivePort = portToUse
      sendIp = packet.publicIp
      _isBound = true
      
      // a UDP bind has been established
      beginReceiving()
    }
    statusPublisher.send(UdpStatus(error: nil, host: sendIp, isBound: success, port: _receivePort))
    return success
  }
  
  /// Begin receiving UDP data
  public func beginReceiving() {
    do {
      // Begin receiving
      try _socket.beginReceiving()
      
    } catch let error {
      // read error
      statusPublisher.send(UdpStatus(error: error, host: sendIp, isBound: true, port: _receivePort))
    }
  }
  
  /// Unbind from the UDP port
  public func unbind(reason: String) {
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
  public func register(clientHandle: Handle?) {
    guard clientHandle != nil else {
      // should not happen
      _log("UdpStream: No client handle in register UDP", .error, #function, #file, #line)
      return
    }
    // register & keep open the router (on a background queue)
    _registerQ.async { [unowned self] in
      while self._socket != nil && !self._isRegistered && self._isBound {

        self._log("UdpStream: register wan, handle = " + clientHandle!.hex, .debug, #function, #file, #line)

        // send a Registration command
        let cmd = "client udp_register handle=" + clientHandle!.hex
        self.send(cmd.data(using: String.Encoding.ascii, allowLossyConversion: false)!)

        // pause
        usleep(self.kRegistrationDelay)
      }
      self._log("UdpStream: register wan exited, Registration = \(self._isRegistered)", .debug, #function, #file, #line)
    }
  }
}
