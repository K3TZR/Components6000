//
//  WanListener.swift
//  Components6000/Discovery/Wan
//
//  Created by Douglas Adams on 12/5/21.
//

import Foundation
import CocoaAsyncSocket
import Combine

import Login
import Shared

public enum WanListenerError: Error {
  case kFailedToObtainIdToken
  case kFailedToConnect
}

public struct SmartlinkTestResult: Equatable {
  public var upnpTcpPortWorking = false
  public var upnpUdpPortWorking = false
  public var forwardTcpPortWorking = false
  public var forwardUdpPortWorking = false
  public var natSupportsHolePunch = false
  public var radioSerial = ""
  
  public init() {}
  
  // format the result as a String
  public var result: String {
        """
        Forward Tcp Port:\t\t\(forwardTcpPortWorking)
        Forward Udp Port:\t\t\(forwardUdpPortWorking)
        UPNP Tcp Port:\t\t\(upnpTcpPortWorking)
        UPNP Udp Port:\t\t\(upnpUdpPortWorking)
        Nat Hole Punch:\t\t\(natSupportsHolePunch)
        """
  }
  
  // result was Success / Failure
  public var success: Bool {
    (
      forwardTcpPortWorking == true &&
      forwardUdpPortWorking == true &&
      upnpTcpPortWorking == false &&
      upnpUdpPortWorking == false &&
      natSupportsHolePunch  == false) ||
    (
      forwardTcpPortWorking == false &&
      forwardUdpPortWorking == false &&
      upnpTcpPortWorking == true &&
      upnpUdpPortWorking == true &&
      natSupportsHolePunch  == false)
  }
}

///  WanListener Class implementation
///      connect to the Smartlink server which announces the presence
///      of Smartlink-accessible Radio(s), publishes changes
final class WanListener: NSObject, ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public private(set) var isListening: Bool = false
  
  @Published public var callsign: String?
  @Published public var handle: Handle?
  @Published public var publicIp: String?
  @Published public var serial: String?
  @Published public var testResult: SmartlinkTestResult?
  @Published public var userName: String?
  
  static let kTimeout: Double = 5.0
  
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
  private let _pingQ = DispatchQueue(label: "WanListener.pingQ")
  private var _platform: String?
  private var _previousIdToken: IdToken?
  private var _pwd: String?
  private let _socketQ = DispatchQueue(label: "WanListener.socketQ")
  private var _timeout = 0.0                // seconds
  private var _user: String?
  
  let _log = LogProxy.sharedInstance.log
  
  private let kSmartlinkHost = "smartlink.flexradio.com"
  private let kSmartlinkPort: UInt16 = 443
  private let kAppName = "Components6000.Discovery"
  private let kPlatform = "macOS"
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  convenience init(_ discovery: Discovery, timeout: Double = kTimeout) {
    self.init()
    
    _timeout = timeout
    _discovery = discovery
    
    // get a socket & set it's parameters
    _tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: _socketQ)
    _tcpSocket.isIPv4PreferredOverIPv6 = true
    _tcpSocket.isIPv6Enabled = false
    
    _log("Discovery: Wan Listener TCP Socket initialized", .debug, #function, #file, #line)
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Start listening given a Smartlink email
  /// - Parameters:
  ///   - smartlinkEmail:     an email address associated with the Smartlink account
  func start(using smartlinkEmail: String?, forceLogin: Bool) throws {
    guard forceLogin == false else { throw WanListenerError.kFailedToObtainIdToken }
    // obtain an ID Token
    if let idToken = _authentication.getValidIdToken(from: _previousIdToken, or: smartlinkEmail) {
      _previousIdToken = idToken
      _log("Discovery: Wan Listener IdToken obtained from previous credentials", .debug, #function, #file, #line)
      // use the ID Token to connect to the Smartlink service
      do {
        try connectToSmartlink(using: idToken)
      } catch {
        throw WanListenerError.kFailedToConnect
      }
      
    } else {
      throw WanListenerError.kFailedToObtainIdToken
    }
  }
  
  /// Start listening given a User / Pwd
  /// - Parameters:
  ///   - loginResult:           a struct with email & pwd
  func start(using loginResult: LoginResult) throws {
    if let idToken = _authentication.requestTokens(using: loginResult) {
      _previousIdToken = idToken
      _log("Discovery: Wan Listener IdToken obtained from login credentials", .debug, #function, #file, #line)
      // use the ID Token to connect to the Smartlink service
      do {
        try connectToSmartlink(using: idToken)
      } catch {
        throw WanListenerError.kFailedToConnect
      }
      
    } else {
      throw WanListenerError.kFailedToObtainIdToken
    }
  }
  
  /// Send a command to the server using TLS
  /// - Parameter cmd:                command text
  func sendTlsCommand(_ cmd: String, timeout: TimeInterval = kTimeout, tag: Int = 1) {
    // send the specified command to the SmartLink server using TLS
    let command = cmd + "\n"
    _tcpSocket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: timeout, tag: 0)
  }
  
  /// stop the listener
  func stop() {
    _cancellables.removeAll()
    _tcpSocket.disconnect()
    DispatchQueue.main.async { self.isListening = false }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Initiate a connection to the Smartlink server
  /// - Parameters:
  ///   - idToken:        an ID Token
  ///   - timeout:        timeout (seconds)
  private func connectToSmartlink(using idToken: IdToken) throws {
    _idToken = idToken    // used later by socketDidSecure
    
    // try to connect
    do {
      try _tcpSocket.connect(toHost: kSmartlinkHost, onPort: kSmartlinkPort, withTimeout: _timeout)
      _log("Discovery: Wan Listener TCP Socket connection initiated", .debug, #function, #file, #line)
      DispatchQueue.main.async { self.isListening = true }
      
    } catch _ {
      throw WanListenerError.kFailedToConnect
    }
  }
  
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
    _log("Discovery: Wan Listener started pinging smartlink server", .debug, #function, #file, #line)
    
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
    
    _log("Discovery: Wan Listener TCP Socket connection established", .debug, #function, #file, #line)
    
    // initiate a secure (TLS) connection to the Smartlink server
    var tlsSettings = [String : NSObject]()
    tlsSettings[kCFStreamSSLPeerName as String] = kSmartlinkHost as NSObject
    _tcpSocket.startTLS(tlsSettings)
    
    _log("Discovery: Wan Listener TLS Socket connection initiated", .debug, #function, #file, #line)
    
    DispatchQueue.main.async { self.isListening = true }
  }
  
  public func socketDidSecure(_ sock: GCDAsyncSocket) {
    _log("Discovery: Wan Listener TLS Socket did secure", .debug, #function, #file, #line)
    
    // start pinging SmartLink server
    startPinging()
    
    // register the Application / token pair with the SmartLink server
    sendTlsCommand("application register appName=\(kAppName) platform=\(kPlatform) token=\(_idToken!)", timeout: _timeout, tag: 0)
    
    // start reading
    DispatchQueue.main.async { self.isListening = true }
    _log("Discovery: Wan Listener is listening", .debug, #function, #file, #line)
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
    _log("Discovery: Wan Listener TCP socket disconnected \(error) from: Host=\(_currentHost ?? "nil") Port=\(_currentPort)",
         err == nil ? .debug : .warning,
         #function, #file, #line)
    
    DispatchQueue.main.async { self.isListening = false }
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
