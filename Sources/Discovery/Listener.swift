//
//  Listener.swift
//  TestDiscoveryPackage/Discovery
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import Combine
import CocoaAsyncSocket
import Shared

//public enum PacketAction {
//  case added
//  case updated
//  case deleted
//}
//
//public struct PacketUpdate: Equatable {
//  public var action: PacketAction
//  public var packet: Packet
//  public var packets: [Packet]
//
//  public init(_ action: PacketAction, packet: Packet, packets: [Packet]) {
//    self.action = action
//    self.packet = packet
//    self.packets = packets
//  }
//}
//
//public enum ClientAction {
//  case add
//  case update
//  case delete
//}
//public struct ClientUpdate: Equatable {
//  public var action: ClientAction
//  public var client: GuiClient
//
//  public init(_ action: ClientAction, client: GuiClient) {
//    self.action = action
//    self.client = client
//  }
//}

/// Discovery implementation
///
///      listens for the udp broadcasts announcing the presence
///      of a Flex-6000 Radio, publishes changes
///
public final class Listener: NSObject {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var packetPublisher = PassthroughSubject<PacketUpdate, Never>()
  public var clientPublisher = PassthroughSubject<ClientUpdate, Never>()

//  public enum PacketAction {
//    case added
//    case updated
//    case deleted
//  }
//
//  public struct PacketUpdate: Equatable {
//    public var action: PacketAction
//    public var packet: Packet
//    public var packets: [Packet]
//
//    public init(_ action: PacketAction, packet: Packet, packets: [Packet]) {
//      self.action = action
//      self.packet = packet
//      self.packets = packets
//    }
//  }

//  public enum ClientAction {
//    case add
//    case update
//    case delete
//  }
//  public struct ClientUpdate: Equatable {
//    public var action: ClientAction
//    public var client: GuiClient
//
//    public init(_ action: ClientAction, client: GuiClient) {
//      self.action = action
//      self.client = client
//    }
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _packets = Packets()
  private var _cancellables = Set<AnyCancellable>()
  private var _udpSocket: GCDAsyncUdpSocket!
  private let _udpQ = DispatchQueue(label: "DiscoveryListener" + ".udpQ")
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(port: UInt16 = 4992, checkInterval: TimeInterval = 1.0, timeout: TimeInterval = 10.0) {
    super.init()
    
    // create a Udp socket and set options
    let _udpSocket = GCDAsyncUdpSocket( delegate: self, delegateQueue: _udpQ )
    _udpSocket.setPreferIPv4()
    _udpSocket.setIPv6Enabled(false)
    
    do {
      try _udpSocket.enableReusePort(true)
      try _udpSocket.bind(toPort: port)
      try _udpSocket.beginReceiving()
      
    } catch let error as NSError {
      fatalError("Discovery: \(error.localizedDescription)")
    }
    // setup a timer to watch for Radio timeouts
    Timer.publish(every: checkInterval, on: .main, in: .default)
      .autoconnect()
      .sink { now in
        let deletedList = self._packets.remove(condition: {abs($0.lastSeen.timeIntervalSince(now)) > timeout} )
        for packet in deletedList {
          self.packetPublisher.send(PacketUpdate(.deleted, packet: packet, packets: self._packets.collection))
        }
      }
      .store(in: &_cancellables)
  }
  
  deinit {
    _cancellables = Set<AnyCancellable>()   // probably unnecessary
    _udpSocket?.close()
  }
    
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Process an incoming DiscoveryPacket
  /// - Parameter newPacket: the packet
  private func process(_ packet: Packet) {
    var newPacket: Packet
    var prevPacket: Packet

    newPacket = packet
    
    // is it a Packet that has been seen previously?
    if let index = _packets.isKnownPacket(packet) {
      prevPacket = _packets.collection[index]
      
      // YES, known packet, has it changed?
      if newPacket.isDifferent(from: prevPacket) {
        
        // YES, changed, parse its GuiClients
        let (additions, deletions) = newPacket.parse()

        // update it and publish
        _packets.update(newPacket)
        packetPublisher.send(PacketUpdate(.updated, packet: newPacket, packets: _packets.collection))
        for client in additions {
          clientPublisher.send(ClientUpdate(.add, client: client))
        }
        for client in deletions {
          clientPublisher.send(ClientUpdate(.delete, client: client))
        }
        return

      } else {
        // NO, same as previous packet, no action
        return
      }
    }
    // NO, not seen previously, parse its GuiClients
    _ = newPacket.parse()

    // add it and publish
    _packets.add(newPacket)
    packetPublisher.send(PacketUpdate(.added, packet: newPacket, packets: _packets.collection))
    for client in newPacket.guiClients {
      clientPublisher.send(ClientUpdate(.add, client: client))
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncUdpSocketDelegate extension

extension Listener: GCDAsyncUdpSocketDelegate {
  /// The Socket received data
  ///
  /// - Parameters:
  ///   - sock:           the GCDAsyncUdpSocket
  ///   - data:           the Data received
  ///   - address:        the Address of the sender
  ///   - filterContext:  the FilterContext
  public func udpSocket(_ sock: GCDAsyncUdpSocket,
                        didReceive data: Data,
                        fromAddress address: Data,
                        withFilterContext filterContext: Any?) {
    // VITA packet?
    guard let vita = Vita.decode(from: data) else { return }
    
    // YES, Discovery Packet?
    guard let packet = parseDiscovery(from: vita) else { return }
    
    // YES, process it
    process(packet)
  }
}

extension Listener {

  enum DiscoveryTokens : String {
    case lastSeen                   = "last_seen"                   // not a real token
    
    case availableClients           = "available_clients"           // newApi, local only
    case availablePanadapters       = "available_panadapters"       // newApi, local only
    case availableSlices            = "available_slices"            // newApi, local only
    case callsign
    case discoveryVersion           = "discovery_protocol_version"  // local only
    case firmwareVersion            = "version"
    case fpcMac                     = "fpc_mac"                     // local only
    case guiClientHandles           = "gui_client_handles"          // newApi
    case guiClientHosts             = "gui_client_hosts"            // newApi
    case guiClientIps               = "gui_client_ips"              // newApi
    case guiClientPrograms          = "gui_client_programs"         // newApi
    case guiClientStations          = "gui_client_stations"         // newApi
    case inUseHost                  = "inuse_host"                  // deprecated -- local only
    case inUseHostWan               = "inusehost"                   // deprecated -- smartlink only
    case inUseIp                    = "inuse_ip"                    // deprecated -- local only
    case inUseIpWan                 = "inuseip"                     // deprecated -- smartlink only
    case licensedClients            = "licensed_clients"            // newApi, local only
    case maxLicensedVersion         = "max_licensed_version"
    case maxPanadapters             = "max_panadapters"             // newApi, local only
    case maxSlices                  = "max_slices"                  // newApi, local only
    case model
    case nickname                   = "nickname"                    // local only
    case port                                                       // local only
    case publicIp                   = "ip"                          // local only
    case publicIpWan                = "public_ip"                   // smartlink only
    case publicTlsPort              = "public_tls_port"             // smartlink only
    case publicUdpPort              = "public_udp_port"             // smartlink only
    case publicUpnpTlsPort          = "public_upnp_tls_port"        // smartlink only
    case publicUpnpUdpPort          = "public_upnp_udp_port"        // smartlink only
    case radioLicenseId             = "radio_license_id"
    case radioName                  = "radio_name"                  // smartlink only
    case requiresAdditionalLicense  = "requires_additional_license"
    case serialNumber               = "serial"
    case status
    case upnpSupported              = "upnp_supported"              // smartlink only
    case wanConnected               = "wan_connected"               // Local only
  }

  /// Parse a Vita class containing a Discovery broadcast
  /// - Parameter vita:   a Vita packet
  /// - Returns:          a DiscoveryPacket (or nil)
  func parseDiscovery(from vita: Vita) -> Packet? {
    // is this a Discovery packet?
    if vita.classIdPresent && vita.classCode == .discovery {
      // Payload is a series of strings of the form <key=value> separated by ' ' (space)
      var payloadData = NSString(bytes: vita.payloadData, length: vita.payloadSize, encoding: String.Encoding.ascii.rawValue)! as String
      
      // eliminate any Nulls at the end of the payload
      payloadData = payloadData.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
      
      return populatePacket( payloadData.keyValuesArray() )
    }
    return nil
  }
  
  private func populatePacket(_ properties: KeyValuesArray) -> Packet? {
    // YES, create a minimal packet with now as "lastSeen"
    var packet = Packet()
    
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = DiscoveryTokens(rawValue: property.key) else {
        // log it and ignore the Key
        //                LogProxy.sharedInstance.libMessage("Unknown Discovery token - \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      switch token {
        
      case .availableClients:           packet.availableClients = property.value.iValue      // newApi only *#
      case .availablePanadapters:       packet.availablePanadapters = property.value.iValue  // newApi only *#
      case .availableSlices:            packet.availableSlices = property.value.iValue       // newApi only *#
      case .callsign:                   packet.callsign = property.value                      // *#
      case .discoveryVersion:           packet.discoveryVersion = property.value             // local only *
      case .firmwareVersion:            packet.firmwareVersion = property.value               // *#
      case .fpcMac:                     packet.fpcMac = property.value                       // local only *
      case .guiClientHandles:           packet.guiClientHandles = property.value             // newApi only *#
      case .guiClientHosts:             packet.guiClientHosts = property.value               // newApi only *#
      case .guiClientIps:               packet.guiClientIps = property.value                 // newApi only *#
      case .guiClientPrograms:          packet.guiClientPrograms = property.value            // newApi only *#
      case .guiClientStations:          packet.guiClientStations = property.value            // newApi only *#
      case .inUseHost:                  packet.inUseHost = property.value                    // deprecated in newApi *
      case .inUseHostWan:               packet.inUseHost = property.value                    // deprecated in newApi
      case .inUseIp:                    packet.inUseIp = property.value                      // deprecated in newApi *
      case .inUseIpWan:                 packet.inUseIp = property.value                      // deprecated in newApi
      case .licensedClients:            packet.licensedClients = property.value.iValue       // newApi only *
      case .maxLicensedVersion:         packet.maxLicensedVersion = property.value            // *#
      case .maxPanadapters:             packet.maxPanadapters = property.value.iValue        // newApi only *
      case .maxSlices:                  packet.maxSlices = property.value.iValue             // newApi only *
      case .model:                      packet.model = property.value                        // *#
      case .nickname:                   packet.nickname = property.value                      // *#
      case .port:                       packet.port = property.value.iValue                   // *
      case .publicIp:                   packet.publicIp = property.value                      // *#
      case .publicIpWan:                packet.publicIp = property.value
      case .publicTlsPort:              packet.publicTlsPort = property.value.iValue         // smartlink only#
      case .publicUdpPort:              packet.publicUdpPort = property.value.iValue         // smartlink only#
      case .publicUpnpTlsPort:          packet.publicUpnpTlsPort = property.value.iValue     // smartlink only#
      case .publicUpnpUdpPort:          packet.publicUpnpUdpPort = property.value.iValue     // smartlink only#
      case .radioName:                  packet.nickname = property.value
      case .radioLicenseId:             packet.radioLicenseId = property.value                // *#
      case .requiresAdditionalLicense:  packet.requiresAdditionalLicense = property.value.bValue  // *#
      case .serialNumber:               packet.serialNumber = property.value                  // *#
      case .status:                     packet.status = property.value                        // *#
      case .upnpSupported:              packet.upnpSupported = property.value.bValue         // smartlink only#
      case .wanConnected:               packet.wanConnected = property.value.bValue          // local only *
        
        // satisfy the switch statement, not a real token
      case .lastSeen:                   break
      }
    }
    return packet
  }
}
