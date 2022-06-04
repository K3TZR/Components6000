//
//  TcpCommand.swift
//  Components6000/TcpCommands
//
//  Created by Douglas Adams on 12/24/21.
//

import Foundation
import CocoaAsyncSocket
import Combine

import Shared

// ----------------------------------------------------------------------------
// MARK: - Public structs and enums

public enum TcpStatusType {
  case didConnect
  case didSecure
  case didDisconnect
}

public enum TcpMessageDirection {
  case received
  case sent
}

public struct TcpMessage {
  public var timeInterval: TimeInterval
  public var direction: TcpMessageDirection
  public var text: String
}

public struct TcpStatus: Identifiable, Equatable {
  public static func == (lhs: TcpStatus, rhs: TcpStatus) -> Bool {
    lhs.id == rhs.id
  }
  
  public init(_ statusType: TcpStatusType, host: String, port: UInt16, error: Error? = nil, reason: String? = nil) {
    self.statusType = statusType
    self.host = host
    self.port = port
    self.error = error
    self.reason = reason
  }
  
  public var id = UUID()
  public var statusType: TcpStatusType = .didDisconnect
  public var host = ""
  public var port: UInt16 = 0
  public var error: Error?
  public var reason: String?
}

///  Tcp Command Class implementation
///      manages all Tcp communication with a Radio
final public class Tcp: NSObject {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var receivedPublisher = PassthroughSubject<TcpMessage, Never>()
  public var sentPublisher = PassthroughSubject<TcpMessage, Never>()
  public var statusPublisher = PassthroughSubject<TcpStatus, Never>()

  public private(set) var interfaceIpAddress = "0.0.0.0"
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  //  let _log = LogProxy.sharedInstance.log
    
  private let _log: Log = { msg,level,function,file,line in
    NotificationCenter.default.post(name: logEntryNotification, object: LogEntry(msg, level, function, file, line))
  }
  var _packetSource: PacketSource?
  let _receiveQ = DispatchQueue(label: "TcpCommand.receiveQ")
  let _sendQ = DispatchQueue(label: "TcpCommand.sendQ")
  var _socket: GCDAsyncSocket!
  var _startTime: Date?
  var _timeout = 0.0   // seconds

  static var q = DispatchQueue(label: "TcpSequenceQ")

  @Atomic(0, q) var sequenceNumber: Int

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
    
    _log("TcpCommand: TCP socket initialized", .debug, #function, #file, #line)
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
      
    case (.smartlink, true):  portToUse = packet.negotiatedHolePunchPort
    case (.smartlink, false): portToUse = packet.publicTlsPort!
    default:                  portToUse = packet.port                     
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
        _log("TcpCommand: connect to the \(String(describing: localInterface)) interface, \(packet.publicIp) on port \(portToUse)", .debug, #function, #file, #line)

      } else {
        // connect on the default interface
        try _socket.connect(toHost: packet.publicIp, onPort: UInt16(portToUse), withTimeout: _timeout)
        _log("TcpCommand: connect to the default interface, \(packet.publicIp) on port \(portToUse)", .debug, #function, #file, #line)
      }
      
    } catch _ {
      // connection attemp failed
      _log("TcpCommand: connection failed", .debug, #function, #file, #line)
      success = false
    }
    //        if success { _isWan = packet.isWan ; _seqNum = 0 }
    if success {
      sequenceNumber = 0
      _log("TcpCommand: connection successful", .debug, #function, #file, #line)
    }
    return success
  }
  
  /// Disconnect TCP from the Radio (hardware)
  public func disconnect() {
    _socket.disconnect()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods

  func readNext() {
    _socket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncSocketDelegate extension

extension Tcp: GCDAsyncSocketDelegate {
  
  public func socketDidSecure(_ sock: GCDAsyncSocket) {
    // TLS connection complete
    _log("TcpCommand: TLS socket did secure", .debug, #function, #file, #line)
    readNext()
    statusPublisher.send( TcpStatus(.didSecure,
                                    host: sock.connectedHost ?? "",
                                    port: sock.connectedPort,
                                    error: nil))
  }
  
  public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
    // no validation required
    _log("TcpCommand: TLS socket did receive trust", .debug, #function, #file, #line)
    completionHandler(true)
  }

  public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    _log("TcpCommand: socket disconnected \(err == nil ? "" : "with error \(err!.localizedDescription)")", err == nil ? .debug : .warning, #function, #file, #line)
    statusPublisher.send( TcpStatus(.didDisconnect,
                                    host: "",
                                    port: 0,
                                    error: err))
  }
  
  public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
    // Connected
    interfaceIpAddress = host
    
    // mark the beginning
    _startTime = Date()

    // is this a Wan connection?
    if _packetSource == .smartlink {
      // YES, secure the connection using TLS
      sock.startTLS( [GCDAsyncSocketManuallyEvaluateTrust : 1 as NSObject] )
      _log("TcpCommand: socket connected to Smartlink \(host) on port \(port), TLS initialized", .debug, #function, #file, #line)

    } else {
      // NO, we're connected
      _log("TcpCommand: socket connected to Local \(host) on port \(port)", .debug, #function, #file, #line)
      statusPublisher.send( TcpStatus(.didConnect,
                                      host: host,
                                      port: port,
                                      error: nil))
      // trigger the next read
      readNext()
    }
  }
}

