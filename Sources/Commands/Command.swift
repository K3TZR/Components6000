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

public struct TcpStatus: Identifiable, Equatable {
  public static func == (lhs: TcpStatus, rhs: TcpStatus) -> Bool {
    lhs.id == rhs.id
  }
  
  public var id = UUID()
  var isConnected = false
  var host = ""
  var port: UInt16 = 0
  var error: Error?
}

///  Command Manager Class implementation
///      manages all Tcp communication with a Radio
final public class Command: NSObject {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var commandPublisher = PassthroughSubject<Substring, Never>()
  public var statusPublisher = PassthroughSubject<TcpStatus, Never>()

  public private(set) var interfaceIpAddress = "0.0.0.0"
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  let _log = LogProxy.sharedInstance.publish
  let _receiveQ = DispatchQueue(label: "Command.receiveQ")
  let _sendQ = DispatchQueue(label: "Command.sendQ")
  var _socket: GCDAsyncSocket!
  var _timeout = 0.0   // seconds
  var _packetSource: PacketSource?
  
  @Atomic(0) var sequenceNumber: Int
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Command Manager
  /// - Parameters:
  ///   - timeout:        connection timeout (seconds)
  public init(timeout: Double = 0.5) {
    _timeout = timeout
    super.init()
    
    // get a socket & set it's parameters
    _socket = GCDAsyncSocket(delegate: self, delegateQueue: _receiveQ)
    _socket.isIPv4PreferredOverIPv6 = true
    _socket.isIPv6Enabled = false
    
    _log(LogEntry("Command: TCP socket initialized", .debug, #function, #file, #line))
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
        _log(LogEntry("Command: connect to the \(String(describing: localInterface)) interface, \(packet.publicIp) on port \(portToUse)", .debug, #function, #file, #line))

      } else {
        // connect on the default interface
        try _socket.connect(toHost: packet.publicIp, onPort: UInt16(portToUse), withTimeout: _timeout)
        _log(LogEntry("Command: connect to the default interface, \(packet.publicIp) on port \(portToUse)", .debug, #function, #file, #line))
      }
      
    } catch _ {
      // connection attemp failed
      _log(LogEntry("Command: connection failed", .debug, #function, #file, #line))
      success = false
    }
    //        if success { _isWan = packet.isWan ; _seqNum = 0 }
    if success {
      sequenceNumber = 0
      _log(LogEntry("Command: connection successful", .debug, #function, #file, #line))
    }
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
    let assignedNumber = sequenceNumber
    
    _sendQ.sync {
      // assemble the command
      let command =  "C" + "\(diagnostic ? "D" : "")" + "\(self.sequenceNumber)|" + cmd + "\n"
      
      // send it, no timeout, tag = segNum
      self._socket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: -1, tag: assignedNumber)
      
      // atomically increment the Sequence Number
      $sequenceNumber.mutate { $0 += 1}

      // TODO: REMOVE THIS LOG
      _log(LogEntry("-----> Command: did send \(command)", .debug, #function, #file, #line))
    }
    // return the Sequence Number used by this send
    return UInt(assignedNumber)
  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncSocketDelegate extension

extension Command: GCDAsyncSocketDelegate {
  
  public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    // TODO: REMOVE THIS LOG
    _log(LogEntry("-----> Command: socket did receive -> \(String(data: data, encoding: .ascii) ?? "")", .debug, #function, #file, #line))

    // publish the received data
    if let text = String(data: data, encoding: .ascii)?.dropLast() {
      commandPublisher.send(text)
    }
    // trigger the next read
    _socket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
  
  public func socketDidSecure(_ sock: GCDAsyncSocket) {
    // TLS connection complete
    _log(LogEntry("Command: TLS socket did secure", .debug, #function, #file, #line))
    statusPublisher.send(
      TcpStatus(isConnected: true,
                host: sock.connectedHost ?? "",
                port: sock.connectedPort,
                error: nil)
    )
  }
  
  public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
    // there are no validations for the radio connection
    _log(LogEntry("Command: TLS socket did receive trust", .debug, #function, #file, #line))
    completionHandler(true)
  }

  public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    _log(LogEntry("Command: socket disconnected \(err == nil ? "" : "with error")", .debug, #function, #file, #line))
    statusPublisher.send(
      TcpStatus(isConnected: false,
                host: "",
                port: 0,
                error: err)
    )
  }
  
  public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
    // Connected
    //        interfaceIpAddress = sock.localHost!
    interfaceIpAddress = host
    
    // is this a Wan connection?
    if _packetSource == .smartlink {
      // YES, secure the connection using TLS
      sock.startTLS( [GCDAsyncSocketManuallyEvaluateTrust : 1 as NSObject] )
      _log(LogEntry("Command: socket connected to Smartlink \(host) on port \(port), TLS initialized", .debug, #function, #file, #line))

    } else {
      // NO, we're connected
      _log(LogEntry("Command: socket connected to Local \(host) on port \(port)", .debug, #function, #file, #line))
      statusPublisher.send(
        TcpStatus(isConnected: true,
                  host: host,
                  port: port,
                  error: nil)
      )
      // trigger the next read
      _socket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)

    }
  }
}

