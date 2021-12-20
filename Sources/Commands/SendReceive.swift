//
//  SendReceive.swift
//  Components6000/Commands
//
//  Created by Douglas Adams on 12/4/21.
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import Shared

///  SendReceive Class implementation
///      manages TCP communication to/from a Radio
final public class SendReceive: NSObject {
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @Atomic(0) private var _sequenceNumber: Int
  private let _tcpReceiveQ = DispatchQueue(label: "Commands.tcpReceiveQ")
  private let _tcpSendQ = DispatchQueue(label: "Commands.tcpSendQ")
  private var _tcpSocket: GCDAsyncSocket!
  private var _timeout = 0.5   // seconds
    
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public override init() {
    super.init()
    
    // get a socket & set it's parameters
    _tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: _tcpReceiveQ)
    _tcpSocket.isIPv4PreferredOverIPv6 = true
    _tcpSocket.isIPv6Enabled = false
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Attempt to connect to the Radio (hardware)
  /// - Parameters:
  ///   - packet:                 a DiscoveryPacket
  /// - Returns:                  success / failure
  public func connect(_ packet: Packet) -> Bool {
    var portToUse = 0
//    var localInterface: String?
    var success = true
    
    // identify the port
//    switch (packet.isWan, packet.requiresHolePunch) {
//
//    case (true, true):  portToUse = packet.negotiatedHolePunchPort!   // isWan w/hole punch
//    case (true, false): portToUse = packet.publicTlsPort!             // isWan
//    default:
    portToUse = packet.port                      // local
//    }
    // attempt a connection
    do {
//      if packet.isWan && packet.requiresHolePunch {
//        // insure that the localInterfaceIp has been specified
//        guard packet.localInterfaceIP != "0.0.0.0" else { return false }
//        // create the localInterfaceIp value
//        localInterface = packet.localInterfaceIP + ":" + String(portToUse)
//
//        // connect via the localInterface
//        try _tcpSocket.connect(toHost: packet.publicIp, onPort: UInt16(portToUse), viaInterface: localInterface, withTimeout: _timeout)
//
//      } else {
        // connect on the default interface
        try _tcpSocket.connect(toHost: packet.publicIp, onPort: UInt16(portToUse), withTimeout: _timeout)
//      }
      
    } catch _ {
      // connection attemp failed
      success = false
    }
    //        if success { _isWan = packet.isWan ; _seqNum = 0 }
//    if success { _isWan = packet.isWan ; sequenceNumber = 0 }
    if success { _sequenceNumber = 0 }
    return success
  }
  /// Disconnect TCP from the Radio (hardware)
  public func disconnect() {
    _tcpSocket.disconnect()
  }
  
  /// Send a Command to the Radio (hardware)
  /// - Parameters:
  ///   - cmd:            a Command string
  ///   - diagnostic:     whether to add "D" suffix
  /// - Returns:          the Sequence Number of the Command
  public func send(_ cmd: String, diagnostic: Bool = false) -> UInt {
    var lastSequenceNumber : Int = 0
    var command = ""
    
    _tcpSendQ.sync {
      // assemble the command
      command =  "C" + "\(diagnostic ? "D" : "")" + "\(self._sequenceNumber)|" + cmd + "\n"
      
      // send it, no timeout, tag = segNum
      self._tcpSocket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: -1, tag: Int(self._sequenceNumber))
      
      lastSequenceNumber = _sequenceNumber
      
      // increment the Sequence Number
      $_sequenceNumber.mutate { $0 += 1}
    }
    // TODO
    // publish the event
//    self._delegate?.didSend(command)
    
    // return the Sequence Number of the last command
    return UInt(lastSequenceNumber)
  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncSocketDelegate extension

extension SendReceive: GCDAsyncSocketDelegate {
  // All execute on the tcpReceiveQ
  
  public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    // TODO
    // publish the event and error value
//    _delegate?.didDisconnect(reason: (err == nil) ? "User Initiated" : err!.localizedDescription)
  }
  
  public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
//    interfaceIpAddress = host
    
//    if _isWan {
//      // Wan connection, secure the connection using TLS
//      sock.startTLS( [GCDAsyncSocketManuallyEvaluateTrust : 1 as NSObject] )
//
//    } else {
      // Local connection
      // TODO
      // publish the host and port values
//      _delegate?.didConnect(host: host, port: port)
//    }
  }
  
  public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    if let text = String(data: data, encoding: .ascii) {
      // TODO
      // publish the bytes that were received
    }
    // trigger the next read
    _tcpSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
  
//  public func socketDidSecure(_ sock: GCDAsyncSocket) {
//    // should not happen but...
//    guard _isWan else { return }
//
//    // now we're connected
//
//    // TODO
//    // publish the host and port values
//    _delegate?.didConnect(host: sock.connectedHost ?? "", port: sock.connectedPort)
//  }
  
  public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
    // should not happen but...
//    guard _isWan else { completionHandler(false) ; return }
    
    // there are no validations for the radio connection
    completionHandler(true)
  }
}

//@propertyWrapper
//class Atomic {
//  static let q = DispatchQueue(label: "AtomicQ", attributes: [.concurrent])
//
//  var projectedValue: Atomic { return self }
//
//  private var value : Int
//
//  init(_ wrappedValue: Int) {
//    self.value = wrappedValue
//  }
//
//  var wrappedValue: Int {
//    get { Atomic.q.sync { value }}
//    set { Atomic.q.sync(flags: .barrier) { value = newValue }} }
//
//  func mutate(_ mutation: (inout Int) -> Void) {
//    return Atomic.q.sync(flags: .barrier) { mutation(&value) }
//  }
//}
