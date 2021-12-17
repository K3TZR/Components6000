//
//  WanListener.swift
//  TestSmartlink/Wan
//
//  Created by Douglas Adams on 12/5/21.
//

import Foundation
import CocoaAsyncSocket
import Combine
import Shared
import LogProxy

public enum WanListenerError: Error {
  case kIdTokenError
  case kConnectError
  case kLoginError
}

public struct SmartlinkTestResult {
  
  public var upnpTcpPortWorking         = false
  public var upnpUdpPortWorking         = false
  public var forwardTcpPortWorking      = false
  public var forwardUdpPortWorking      = false
  public var natSupportsHolePunch       = false
  public var radioSerial                = ""
  
  public func string() -> String {
    return """
    UPnP Ports:
    \tTCP:\t\t\(upnpTcpPortWorking.asPassFail)
    \tUDP:\t\(upnpUdpPortWorking.asPassFail)
    Forwarded Ports:
    \tTCP:\t\t\(forwardTcpPortWorking.asPassFail)
    \tUDP:\t\(forwardUdpPortWorking.asPassFail)
    Hole Punch Supported:\t\(natSupportsHolePunch.asYesNo)
    """
  }
}

///  WanListener Class implementation
///      connect to the Smartlink server which announces the presence
///      of Smartlink-accessible Radio(s), publishes changes
final class WanListener: NSObject, ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  @Published public var callsign: String?
  @Published public var handle: Handle?
  @Published public private(set) var isConnected: Bool = false
  @Published public var publicIp: String?
  @Published public var serial: String?
  @Published public var testResult: SmartlinkTestResult?
  @Published public var userName: String?
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  weak var _discovery: Discovery?
  var _tcpSocket: GCDAsyncSocket!
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _appName: String?
  private var _authentication = Authentication()
  private var _cancellables = Set<AnyCancellable>()
  private var _currentHost: String?
  private var _currentPort: UInt16 = 0
  private var _idToken: IdToken? = nil
  private let _pingQ   = DispatchQueue(label: "WanListener.pingQ")
  private var _platform: String?
  private var _previousIdToken: IdToken?
  private var _pwd: String?
  private let _socketQ = DispatchQueue(label: "WanListener.socketQ")
  private var _timeout = 0.0                // seconds
  private var _user: String?

  let _log = LogProxy.sharedInstance.publish

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  convenience init(discovery: Discovery, smartlinkEmail: String, appName: String, platform: String, timeout: Double = 5.0) throws {
    self.init()

    _timeout = timeout
    _discovery = discovery
    
    // get a socket & set it's parameters
    _tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: _socketQ)
    _tcpSocket.isIPv4PreferredOverIPv6 = true
    _tcpSocket.isIPv6Enabled = false
  
    _appName = appName
    _platform = platform

    // obtain an ID Token
    if let idToken = _authentication.getValidIdToken(from: _previousIdToken, or: smartlinkEmail) {
      _previousIdToken = idToken
      // use the ID Token to connect to the Smartlink service
      try start(idToken: idToken)
      
    } else {
      // show Login View to obtain User / Pwd
      let user = _user
      let pwd = _pwd
            
      if let user = user, let pwd = pwd {
        
        if let idToken = _authentication.requestTokens(for: user, pwd: pwd) {
          _previousIdToken = idToken
          // use the ID Token to connect to the Smartlink service
          try start(idToken: idToken)
        }
      } else {
        
        // TODO: Alert, user and pwd required
        throw WanListenerError.kLoginError
      }
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Initiate a connection to the Smartlink server
  /// - Parameters:
  ///   - idToken:        an ID Token
  func start(idToken: IdToken) throws {
    _idToken = idToken
    
    // try to connect
    do {
      try _tcpSocket.connect(toHost: "smartlink.flexradio.com", onPort: 443, withTimeout: _timeout)
      DispatchQueue.main.async { self.isConnected = true }
      _log(LogEntry("Discovery: TCP Socket connection initiated", .debug, #function, #file, #line))

    } catch _ {
      throw WanListenerError.kConnectError
    }
  }
  
  /// stop the listener
  func stop() {
    _cancellables.removeAll()
    _tcpSocket.disconnect()
    DispatchQueue.main.async { self.isConnected = false }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Ping the SmartLink server
  private func startPinging() {
    // setup a timer to watch for Radio timeouts
    Timer.publish(every: 10, on: .main, in: .default)
      .autoconnect()
      .sink { _ in
        // send another Ping
        self.sendTlsCommand("ping from client", timeout: -1)
      }
      .store(in: &_cancellables)
    _log(LogEntry("Discovery: Started pinging", .debug, #function, #file, #line))

  }
  
  /// Send a command to the server using TLS
  /// - Parameter cmd:                command text
  private func sendTlsCommand(_ cmd: String, timeout: TimeInterval, tag: Int = 0) {
    // send the specified command to the SmartLink server using TLS
    let command = cmd + "\n"
    _tcpSocket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: timeout, tag: 0)
  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncSocketDelegate extension

extension WanListener: GCDAsyncSocketDelegate {
  //      All are called on the _socketQ
  //
  //      1. A TCP connection is opened to the SmartLink server
  //      2. A TLS connection is then initiated over the TCP connection
  //      3. The TLS connection "secures" and is now ready for use
  //
  //      If a TLS negotiation fails (invalid certificate, etc) then the socket will immediately close,
  //      and the socketDidDisconnect:withError: delegate method will be called with an error code.
  //
  public func socket(_ sock: GCDAsyncSocket,
                     didConnectToHost host: String,
                     port: UInt16) {
    // Connected to the SmartLink server, save the ip & port
    _currentHost = host
    _currentPort = port
    
    _log(LogEntry("Discovery: TCP Socket connection established", .debug, #function, #file, #line))

    // initiate a secure (TLS) connection to the Smartlink server
    var tlsSettings = [String : NSObject]()
    tlsSettings[kCFStreamSSLPeerName as String] = "smartlink.flexradio.com" as NSObject
    _tcpSocket.startTLS(tlsSettings)

    _log(LogEntry("Discovery: TLS Socket connection initiated", .debug, #function, #file, #line))

    DispatchQueue.main.async { self.isConnected = true }
  }
  
  public func socketDidSecure(_ sock: GCDAsyncSocket) {
    _log(LogEntry("Discovery: TLS Socket did secure", .debug, #function, #file, #line))

    // start pinging SmartLink server
    startPinging()
    
    // register the Application / token pair with the SmartLink server
    sendTlsCommand("application register appName=\(_appName ?? "nil") platform=\(_platform ?? "nil") token=\(_idToken!)", timeout: _timeout, tag: 1)
    
    // start reading
    _tcpSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
  
  public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    // get the bytes that were read
    if let msg = String(data: data, encoding: .ascii) {
      // process the message
      parseVitaPayload(msg)
    }
    // trigger the next read
    _tcpSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
  
  public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    // Disconnected from the Smartlink server
    let error = (err == nil ? "" : " with error: " + err!.localizedDescription)
    _log(LogEntry("Discovery: TCP socket disconnected \(error) from: Host=\(_currentHost ?? "nil") Port=\(_currentPort)",
                  err == nil ? .debug : .warning,
                  #function, #file, #line))

    DispatchQueue.main.async { self.isConnected = false }
    _currentHost = ""
    _currentPort = 0
  }
  
  public func socket(_ sock: GCDAsyncSocket, shouldTimeoutWriteWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
    return 0
  }
  
  public func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
    return 30.0
  }
}
