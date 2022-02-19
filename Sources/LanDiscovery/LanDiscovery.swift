//
//  LanDiscovery.swift
//  Components6000/LanDiscovery
//
//  Created by Douglas Adams on 12/6/21.
//

import Foundation
import Combine
import CocoaAsyncSocket

import Shared
import IdentifiedCollections
import Login

public final class LanDiscovery: NSObject, ObservableObject {
  public static func == (lhs: LanDiscovery, rhs: LanDiscovery) -> Bool {
    lhs === rhs
  }

  // ----------------------------------------------------------------------------
  // MARK: - Publishers
  
  public var clientPublisher = PassthroughSubject<ClientUpdate, Never>()
  public var packetPublisher = PassthroughSubject<PacketUpdate, Never>()
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var packets = IdentifiedArrayOf<Packet>()
  public var stations = IdentifiedArrayOf<Packet>()

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _cancellables = Set<AnyCancellable>()
  private let _formatter = DateFormatter()
  private let _udpQ = DispatchQueue(label: "DiscoveryListener" + ".udpQ")
  private var _udpSocket: GCDAsyncUdpSocket!

  let _log = LogProxy.sharedInstance.log

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(port: UInt16 = 4992, checkInterval: TimeInterval = 1.0, timeout: TimeInterval = 10.0) {
    super.init()
    
    _formatter.timeZone = .current
    _formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    // create a Udp socket and set options
    _udpSocket = GCDAsyncUdpSocket( delegate: self, delegateQueue: _udpQ )
    _udpSocket.setPreferIPv4()
    _udpSocket.setIPv6Enabled(false)
    
    try! _udpSocket.enableReusePort(true)
    try! _udpSocket.bind(toPort: port)
    _log("Discovery: Lan Listener UDP Socket initialized", .debug, #function, #file, #line)
    
    try! _udpSocket.beginReceiving()
    _log("Discovery: Lan Listener is listening", .debug, #function, #file, #line)
    
    // setup a timer to watch for Radio timeouts
    Timer.publish(every: checkInterval, on: .main, in: .default)
      .autoconnect()
      .sink { [self] now in
        remove(condition: { $0.source == .local && abs($0.lastSeen.timeIntervalSince(now)) > timeout } )
      }
      .store(in: &_cancellables)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
//  public func startLanListener() throws {
//    guard _lanListener == nil else { return }
//    _lanListener = LanListener(self)
//  }
  
//  public func stopLanListener() {
//    guard _lanListener != nil else { return }
//    _lanListener?.stop()
//    _lanListener = nil
//  }

//  public func removePackets() {
//    for packet in packets where packet.source == .local {
//      packets[id: packet.id] = nil
//    }
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Process an incoming DiscoveryPacket
  /// - Parameter newPacket: the packet
  func processPacket(_ packet: Packet) {
    var newPacket = packet
    
    // is it a Packet that has been seen previously?
    if let knownPacketId = isKnownRadio(newPacket) {
      // YES, has it changed?
      if newPacket.isDifferent(from: packets[id: knownPacketId]!) {
        // YES, parse the GuiClient fields
        newPacket = newPacket.parseGuiClients()
        let oldPacket = packets[id: knownPacketId]!
        
        // maintain the id from the known packet, update the timestamp
        newPacket.id = knownPacketId
        newPacket.lastSeen = Date()
        // update the known packet
        packets[id: knownPacketId] = newPacket

        // publish and log the packet
        packetPublisher.send(PacketUpdate(.updated, packet: newPacket))
        _log("Discovery: \(newPacket.source.rawValue) packet updated, \(newPacket.serial)", .debug, #function, #file, #line)

        // find, publish & log client additions / deletions
        findClientAdditions(in: newPacket, from: oldPacket)
        findClientDeletions(in: newPacket, from: oldPacket)
        return
      
      } else {
        // NO, update the timestamp
        packets[id: knownPacketId]!.lastSeen = Date()

        return
      }
    }
    // NO, not seen before, parse the GuiClient fields then add it
    newPacket = newPacket.parseGuiClients()
    packets.append(newPacket)

    // publish & log
    packetPublisher.send(PacketUpdate(.added, packet: newPacket))
    _log("Discovery: \(newPacket.source.rawValue) packet added, \(newPacket.serial)", .debug, #function, #file, #line)

    // find, publish & log client additions
    findClientAdditions(in: newPacket)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Remove a packet from the collection
  /// - Parameter condition:  a closure defining the condition for removal
  private func remove(condition: (Packet) -> Bool) {
    for packet in packets where condition(packet) {
      let removedPacket = packets.remove(id: packet.id)
      packetPublisher.send(PacketUpdate(.deleted, packet: removedPacket!))
      
      self._log("Discovery: Lan Listener packet removed, interval = \(abs(removedPacket!.lastSeen.timeIntervalSince(Date())))", .debug, #function, #file, #line)
    }
  }
  
  private func findClientAdditions(in newPacket: Packet, from oldPacket: Packet? = nil) {
    
    for guiClient in newPacket.guiClients {
      if oldPacket == nil || oldPacket?.guiClients[id: guiClient.id] == nil {
        
        // publish & log
        clientPublisher.send(ClientUpdate(.added, client: guiClient, source: newPacket.source))
        _log("Discovery: \(newPacket.source.rawValue) guiClient added, \(guiClient.station)", .debug, #function, #file, #line)
        
        let newStation = Packet(source: newPacket.source)
        var packetCopy = newPacket
        packetCopy.id = newStation.id
        stations[id: newStation.id] = packetCopy

        stations[id: newStation.id]?.guiClientStations = guiClient.station
        stations[id: newStation.id]?.guiClients = [guiClient]
      }
    }
  }

  private func findClientDeletions(in newPacket: Packet, from oldPacket: Packet) {
    
    for guiClient in oldPacket.guiClients {
      if newPacket.guiClients[id: guiClient.id] == nil {
        
        // publish & log
        clientPublisher.send(ClientUpdate(.deleted, client: guiClient, source: newPacket.source))
        _log("Discovery: \(newPacket.source.rawValue) guiClient deleted, \(guiClient.station)", .debug, #function, #file, #line)
        
        for station in stations where station.guiClientStations == guiClient.station {
          stations.remove(station)
        }
      }
    }
  }

  /// Is the packet known (i.e. in the collection)
  /// - Parameter newPacket:  the incoming packet
  /// - Returns:              the id, if any, of the matching packet
  private func isKnownRadio(_ newPacket: Packet) -> UUID? {
    var id: UUID?
    
    for packet in packets where packet.serial == newPacket.serial && packet.publicIp == newPacket.publicIp {
      id = packet.id
      break
    }
    return id
  }

  /// Parse a Vita class containing a Discovery broadcast
  /// - Parameter vita:   a Vita packet
  /// - Returns:          a DiscoveryPacket (or nil)
  private func parseVita(_ vita: Vita) -> Packet? {
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
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncUdpSocketDelegate extension

extension LanDiscovery: GCDAsyncUdpSocketDelegate {
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
    guard let packet = parseVita(vita) else { return }
    
    // YES, process it
    processPacket(packet)
  }
}

extension LanDiscovery {

  enum DiscoveryTokens : String {
    case lastSeen                   = "last_seen"
    
    case availableClients           = "available_clients"
    case availablePanadapters       = "available_panadapters"
    case availableSlices            = "available_slices"
    case callsign
    case discoveryProtocolVersion   = "discovery_protocol_version"
    case version                    = "version"
    case fpcMac                     = "fpc_mac"
    case guiClientHandles           = "gui_client_handles"
    case guiClientHosts             = "gui_client_hosts"
    case guiClientIps               = "gui_client_ips"
    case guiClientPrograms          = "gui_client_programs"
    case guiClientStations          = "gui_client_stations"
    case inUseHost                  = "inuse_host"
    case inUseHostWan               = "inusehost"
    case inUseIp                    = "inuse_ip"
    case inUseIpWan                 = "inuseip"
    case licensedClients            = "licensed_clients"
    case maxLicensedVersion         = "max_licensed_version"
    case maxPanadapters             = "max_panadapters"
    case maxSlices                  = "max_slices"
    case model
    case nickname                   = "nickname"
    case port
    case publicIp                   = "ip"
    case publicIpWan                = "public_ip"
    case publicTlsPort              = "public_tls_port"
    case publicUdpPort              = "public_udp_port"
    case publicUpnpTlsPort          = "public_upnp_tls_port"
    case publicUpnpUdpPort          = "public_upnp_udp_port"
    case radioLicenseId             = "radio_license_id"
    case radioName                  = "radio_name"
    case requiresAdditionalLicense  = "requires_additional_license"
    case serial                     = "serial"
    case status
    case upnpSupported              = "upnp_supported"
    case wanConnected               = "wan_connected"
  }

  func populatePacket(_ properties: KeyValuesArray) -> Packet? {
    // YES, create a minimal packet with now as "lastSeen"
    var packet = Packet()
    
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = DiscoveryTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Discovery: Unknown token - \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      switch token {
        
        // these fields in the received packet are copied to the Packet struct
      case .callsign:                   packet.callsign = property.value
      case .guiClientHandles:           packet.guiClientHandles = property.value
      case .guiClientHosts:             packet.guiClientHosts = property.value
      case .guiClientIps:               packet.guiClientIps = property.value
      case .guiClientPrograms:          packet.guiClientPrograms = property.value
      case .guiClientStations:          packet.guiClientStations = property.value
      case .inUseHost, .inUseHostWan:   packet.inUseHost = property.value
      case .inUseIp, .inUseIpWan:       packet.inUseIp = property.value
      case .model:                      packet.model = property.value
      case .nickname, .radioName:       packet.nickname = property.value
      case .port:                       packet.port = property.value.iValue
      case .publicIp, .publicIpWan:     packet.publicIp = property.value
      case .publicTlsPort:              packet.publicTlsPort = property.value.iValueOpt
      case .publicUdpPort:              packet.publicUdpPort = property.value.iValueOpt
      case .publicUpnpTlsPort:          packet.publicUpnpTlsPort = property.value.iValueOpt
      case .publicUpnpUdpPort:          packet.publicUpnpUdpPort = property.value.iValueOpt
      case .serial:                     packet.serial = property.value
      case .status:                     packet.status = property.value
      case .upnpSupported:              packet.upnpSupported = property.value.bValue
      case .version:                    packet.version = property.value

        // these fields in the received packet are NOT copied to the Packet struct
      case .availableClients:           break // ignored
      case .availablePanadapters:       break // ignored
      case .availableSlices:            break // ignored
      case .discoveryProtocolVersion:   break // ignored
      case .fpcMac:                     break // ignored
      case .licensedClients:            break // ignored
      case .maxLicensedVersion:         break // ignored
      case .maxPanadapters:             break // ignored
      case .maxSlices:                  break // ignored
      case .radioLicenseId:             break // ignored
      case .requiresAdditionalLicense:  break // ignored
      case .wanConnected:               break // ignored

        // satisfy the switch statement
      case .lastSeen:                   break
      }
    }
    return packet
  }
}
