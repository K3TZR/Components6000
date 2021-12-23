//
//  TcpManager.swift
//  Components6000/TcpManager
//
//  Created by Douglas Adams on 12/22/21.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
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

///  TcpManager Class implementation
///      manages a TCP connection to the Radio
final class TcpManager: NSObject {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var receivedDataPublisher = PassthroughSubject<String, Never>()
  public var statusPublisher = PassthroughSubject<TcpStatus, Never>()

  public private(set) var interfaceIpAddress = "0.0.0.0"
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _receiveQ = DispatchQueue(label: "TcpManager.receiveQ")
  private let _sendQ = DispatchQueue(label: "TcpManager.sendQ")
  private var _socket: GCDAsyncSocket!
  private var _timeout = 0.0   // seconds
  private var _packetSource: PacketSource?
  
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
  
  /// Send a Command to the Radio (hardware)
  /// - Parameters:
  ///   - cmd:            a Command string
  ///   - diagnostic:     whether to add "D" suffix
  /// - Returns:          the Sequence Number of the Command
  public func send(_ cmd: String, diagnostic: Bool = false) -> UInt {
    var lastSequenceNumber : Int = 0
    var command = ""
    
    _sendQ.sync {
      // assemble the command
      //            command =  "C" + "\(diagnostic ? "D" : "")" + "\(self._seqNum)|" + cmd + "\n"
      command =  "C" + "\(diagnostic ? "D" : "")" + "\(self.sequenceNumber)|" + cmd + "\n"
      
      // send it, no timeout, tag = segNum
      //            self._tcpSocket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: -1, tag: Int(self._seqNum))
      self._socket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: -1, tag: Int(self.sequenceNumber))
      
      //            lastSeqNum = _seqNum
      lastSequenceNumber = sequenceNumber
      
      // increment the Sequence Number
      //            _seqNum += 1
      $sequenceNumber.mutate { $0 += 1}
    }
//    self._delegate?.didSend(command)
    
    // return the Sequence Number of the last command
    return UInt(lastSequenceNumber)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Read the next data block (with an indefinite timeout)
//  private func readNext() {
//    _tcpSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
//  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncSocketDelegate extension

extension TcpManager: GCDAsyncSocketDelegate {
  // All execute on the tcpReceiveQ
  
  func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
//    _delegate?.didDisconnect(reason: (err == nil) ? "User Initiated" : err!.localizedDescription)
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
  
  func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    // pass the bytes read to the delegate
    if let text = String(data: data, encoding: .ascii) {
      receivedDataPublisher.send(text)
    }
    // trigger the next read
    _socket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
  
  public func socketDidSecure(_ sock: GCDAsyncSocket) {
    // now we're connected
    statusPublisher.send(
      TcpStatus(isConnected: true,
                host: sock.connectedHost ?? "",
                port: sock.connectedPort,
                error: nil)
    )
  }
  
  public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
//    // should not happen but...
//    guard _isWan else { completionHandler(false) ; return }
    
    // there are no validations for the radio connection
    completionHandler(true)
  }
}

