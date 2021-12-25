//
//  TcpManager.swift
//  Components6000/Commands
//
//  Created by Douglas Adams on 12/24/21.
//

import Foundation
import CocoaAsyncSocket
import Combine

import Shared

public struct TcpStatus {
  var isConnected = false
  var host = ""
  var port: UInt16 = 0
  var error: Error?
}

///  Command Manager Class implementation
///      manages all Tcp communication with a Radio
final class Command: NSObject {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var receivedDataPublisher = PassthroughSubject<String, Never>()
  public var statusPublisher = PassthroughSubject<TcpStatus, Never>()

  public private(set) var interfaceIpAddress = "0.0.0.0"
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  let _receiveQ = DispatchQueue(label: "TcpManager.receiveQ")
  let _sendQ = DispatchQueue(label: "TcpManager.sendQ")
  var _socket: GCDAsyncSocket!
  var _timeout = 0.0   // seconds
  var _packetSource: PacketSource?
  
  @Atomic(0) var sequenceNumber: Int
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a TcpManager
  /// - Parameters:
  ///   - tcpReceiveQ:    a serial Queue for Tcp receive activity
  ///   - tcpSendQ:       a serial Queue for Tcp send activity
  ///   - delegate:       a delegate for Tcp activity
  ///   - timeout:        connection timeout (seconds)
  init(timeout: Double = 0.5) {
    _timeout = timeout
    super.init()
    
    // get a socket & set it's parameters
    _socket = GCDAsyncSocket(delegate: self, delegateQueue: _receiveQ)
    _socket.isIPv4PreferredOverIPv6 = true
    _socket.isIPv6Enabled = false
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Attempt to connect to a Radio
  /// - Parameters:
  ///   - packet:                 a DiscoveryPacket
  /// - Returns:                  success / failure
  public func connect(_ packet: Packet) -> Bool {
    var portToUse = 0
    var localInterface: String?
    var success = true
    _packetSource = packet.source
    
    // identify the port
    switch (packet.source, packet.requiresHolePunch) {
      
    case (.smartlink, true):  portToUse = packet.negotiatedHolePunchPort  // isWan w/hole punch
    case (.smartlink, false): portToUse = packet.publicTlsPort!           // isWan
    default:                  portToUse = packet.port                     // local
    }
    // attempt a connection
    do {
      if packet.source == .smartlink && packet.requiresHolePunch {
        // insure that the localInterfaceIp has been specified
        guard packet.localInterfaceIP != "0.0.0.0" else { return false }
        // create the localInterfaceIp value
        localInterface = packet.localInterfaceIP + ":" + String(portToUse)
        
        // connect via the localInterface
        try _socket.connect(toHost: packet.publicIp, onPort: UInt16(portToUse), viaInterface: localInterface, withTimeout: _timeout)
        
      } else {
        // connect on the default interface
        try _socket.connect(toHost: packet.publicIp, onPort: UInt16(portToUse), withTimeout: _timeout)
      }
      
    } catch _ {
      // connection attemp failed
      success = false
    }
    //        if success { _isWan = packet.isWan ; _seqNum = 0 }
    if success { sequenceNumber = 0 }
    return success
  }
  
  /// Disconnect TCP from the Radio (hardware)
  public func disconnect() {
    _socket.disconnect()
  }
  
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncSocketDelegate extension

extension Command: GCDAsyncSocketDelegate {
  // All execute on the tcpReceiveQ
  
  func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    statusPublisher.send(
      TcpStatus(isConnected: false,
                host: "",
                port: 0,
                error: err)
    )
  }
  
  func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
    // Connected
    //        interfaceIpAddress = sock.localHost!
    interfaceIpAddress = host
    
    // is this a Wan connection?
    if _packetSource == .smartlink {
      // YES, secure the connection using TLS
      sock.startTLS( [GCDAsyncSocketManuallyEvaluateTrust : 1 as NSObject] )
      
    } else {
      // NO, we're connected
      statusPublisher.send(
        TcpStatus(isConnected: true,
                  host: host,
                  port: port,
                  error: nil)
      )
    }
  }
}

