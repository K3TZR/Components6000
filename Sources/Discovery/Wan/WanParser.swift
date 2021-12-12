//
//  WanMessageParser.swift
//  TestSmartlink
//
//  Created by Douglas Adams on 12/10/21.
//

import Foundation
import Shared

extension WanListener {
  // ------------------------------------------------------------------------------
  // MARK: - Tokens
  
  private enum ApplicationTokens: String {
    case info
    case registrationInvalid = "registration_invalid"
    case userSettings        = "user_settings"
  }
  private enum ConnectReadyTokens: String {
    case handle
    case serial
  }
  private enum InfoTokens: String {
    case publicIp = "public_ip"
  }
  private enum MessageTokens: String {
    case application
    case radio
    case Received
  }
  private enum RadioTokens: String {
    case connectReady   = "connect_ready"
    case list
    case testConnection = "test_connection"
  }
  private enum TestConnectionTokens: String {
    case forwardTcpPortWorking = "forward_tcp_port_working"
    case forwardUdpPortWorking = "forward_udp_port_working"
    case natSupportsHolePunch  = "nat_supports_hole_punch"
    case radioSerial           = "serial"
    case upnpTcpPortWorking    = "upnp_tcp_port_working"
    case upnpUdpPortWorking    = "upnp_udp_port_working"
  }
  private enum UserSettingsTokens: String {
    case callsign
    case firstName    = "first_name"
    case lastName     = "last_name"
  }

  // ------------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Parse a Vita payload containing a Discovery broadcast
  /// - Parameter text:   a Vita payload
  func parseVitaPayload(_ text: String) {
    let msg = text.trimmingCharacters(in: .whitespacesAndNewlines)
    
    let properties = msg.keyValuesArray()
    
    // Check for unknown Message Types
    guard let token = MessageTokens(rawValue: properties[0].key)  else {
      // log it and ignore the message
      _discovery?.logPublisher.send(LogEntry("WanListener, unknown Message - \(msg)", .warning, #function, #file, #line))
      return
    }
    // which primary message type?
    switch token {
      
    case .application:        parseApplication(Array(properties.dropFirst()))
    case .radio:              parseRadio(Array(properties.dropFirst()), msg: msg)
    case .Received:           break   // ignore message on Test connection
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse a received "application" message
  /// - Parameter properties:        message KeyValue pairs
  private func parseApplication(_ properties: KeyValuesArray) {
    // Check for unknown property (ignore 0th property)
    guard let token = ApplicationTokens(rawValue: properties[0].key)  else {
      // log it and ignore the message
      _discovery?.logPublisher.send(LogEntry("WanListener, unknown application token:, \(properties[1].key)", .warning, #function, #file, #line))
      return
    }
    switch token {
      
    case .info:                     parseApplicationInfo(Array(properties.dropFirst()))
    case .registrationInvalid:      parseRegistrationInvalid(properties)
    case .userSettings:             parseUserSettings(Array(properties.dropFirst()))
    }
  }
  
  /// Parse a received "radio" message
  /// - Parameter msg:        the message (after the primary type)
  private func parseRadio(_ properties: KeyValuesArray, msg: String) {
    // Check for unknown Message Types (ignore 0th property)
    guard let token = RadioTokens(rawValue: properties[0].key)  else {
      // log it and ignore the message
      _discovery?.logPublisher.send(LogEntry("WanListener, unknown radio token: \(properties[1].key)", .warning, #function, #file,#line))
      return
    }
    // which secondary message type?
    switch token {
      
    case .connectReady:       parseRadioConnectReady(Array(properties.dropFirst()))
    case .list:               parseRadioList(msg.dropFirst(11))
    case .testConnection:     parseTestConnectionResults(Array(properties.dropFirst()))
    }
  }
  
  /// Parse a received "application" message
  /// - Parameter properties:         a KeyValuesArray
  private func parseApplicationInfo(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = InfoTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _discovery?.logPublisher.send(LogEntry("WanListener, unknown info token: \(property.key)", .warning, #function, #file, #line))
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .publicIp:       DispatchQueue.main.async { self.publicIp = property.value }
      }
    }
  }
  
  /// Respond to an Invalid registration
  /// - Parameter msg:                the message text
  private func parseRegistrationInvalid(_ properties: KeyValuesArray) {
    _discovery?.logPublisher.send(LogEntry("WanListener, invalid registration: \(properties.count == 3 ? properties[2].key : "")", .warning, #function, #file, #line))
  }
  
  /// Parse a received "user settings" message
  /// - Parameter properties:         a KeyValuesArray
  private func parseUserSettings(_ properties: KeyValuesArray) {
    var callsign: String?
    var firstName: String?
    var lastName: String?
    
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = UserSettingsTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _discovery?.logPublisher.send(LogEntry("WanListener, unknown settings token: \(property.key)", .warning, #function, #file, #line))
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .callsign:       callsign = property.value
      case .firstName:      firstName = property.value
      case .lastName:       lastName = property.value
      }
    }
    
    if firstName != nil && lastName != nil  && callsign != nil{
      // publish
      DispatchQueue.main.async {
        self.userName = firstName! + " " + lastName!
        self.callsign = callsign!
      }
    }
  }
  
  /// Parse a received "connect ready" message
  /// - Parameter properties:         a KeyValuesArray
  private func parseRadioConnectReady(_ properties: KeyValuesArray) {
    var handle: Handle?
    var serial: String?
    
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = ConnectReadyTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _discovery?.logPublisher.send(LogEntry("WanListener, unknown connect token: \(property.key)", .warning, #function, #file, #line))
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .handle:         handle = property.value.handle
      case .serial:         serial = property.value
      }
    }
    
    if handle != nil && serial != nil {
      // publish
      DispatchQueue.main.async {
        self.handle = handle!
        self.serial = serial!
      }
    }
  }
  
  /// Parse a received "radio list" message
  /// - Parameter msg:        the list
  private func parseRadioList(_ msg: String.SubSequence) {
    var publicTlsPortToUse = -1
    var publicUdpPortToUse = -1
    
    // several radios are possible, separate list into its components
    let radioMessages = msg.components(separatedBy: "|")
    
    for message in radioMessages where message != "" {
      if var packet = _discovery?.populatePacket( message.keyValuesArray() ) {
        // now continue to fill the radio parameters
        // favor using the manually defined forwarded ports if they are defined
        if let tlsPort = packet.publicTlsPort, let udpPort = packet.publicUdpPort {
          publicTlsPortToUse = tlsPort
          publicUdpPortToUse = udpPort
          packet.isPortForwardOn = true;
        } else if (packet.upnpSupported) {
          publicTlsPortToUse = packet.publicUpnpTlsPort!
          publicUdpPortToUse = packet.publicUpnpUdpPort!
          packet.isPortForwardOn = false
        }
        
        if ( !packet.upnpSupported && !packet.isPortForwardOn ) {
          /* This will require extra negotiation that chooses
           * a port for both sides to try
           */
          // TODO: We also need to check the NAT for preserve_ports coming from radio here
          // if the NAT DOES NOT preserve ports then we can't do hole punch
          packet.requiresHolePunch = true
        }
        packet.publicTlsPort = publicTlsPortToUse
        packet.publicUdpPort = publicUdpPortToUse
        if let localAddr = _tcpSocket.localHost {
          packet.localInterfaceIP = localAddr
        }
        packet.source = .smartlink
        // add packet to Packets
        _discovery?.processPacket(packet)
      }
    }
  }
  
  /// Parse a received "test results" message
  /// - Parameter properties:         a KeyValuesArray
  private func parseTestConnectionResults(_ properties: KeyValuesArray) {
    var result = SmartlinkTestResult()
    
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = TestConnectionTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _discovery?.logPublisher.send(LogEntry("WanListener, unknown testConnection token: \(property.key)", .warning, #function, #file, #line))
        continue
      }
      
      // Known tokens, in alphabetical order
      switch token {
        
      case .forwardTcpPortWorking:      result.forwardTcpPortWorking = property.value.tValue
      case .forwardUdpPortWorking:      result.forwardUdpPortWorking = property.value.tValue
      case .natSupportsHolePunch:       result.natSupportsHolePunch = property.value.tValue
      case .radioSerial:                result.radioSerial = property.value
      case .upnpTcpPortWorking:         result.upnpTcpPortWorking = property.value.tValue
      case .upnpUdpPortWorking:         result.upnpUdpPortWorking = property.value.tValue
      }
    }
    // publish test result
    DispatchQueue.main.async { self.testResult = result }
  }
}
