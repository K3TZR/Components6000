//
//  Discovery.swift
//  Components6000/Discovery
//
//  Created by Douglas Adams on 12/6/21.
//

import Foundation
import Combine
import Shared
import IdentifiedCollections
import Login

public final class Discovery: Equatable, ObservableObject {
  public static func == (lhs: Discovery, rhs: Discovery) -> Bool {
    lhs === rhs
  }

  // ----------------------------------------------------------------------------
  // MARK: - Publishers
  
  public var clientPublisher = PassthroughSubject<ClientChange, Never>()
  public var packetPublisher = PassthroughSubject<PacketChange, Never>()
  public var testPublisher = PassthroughSubject<SmartlinkTestResult, Never>()
  public var wanStatusPublisher = PassthroughSubject<WanStatus, Never>()
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var packets = IdentifiedArrayOf<Packet>()
  public var stations = IdentifiedArrayOf<Packet>()

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _lanListener: LanListener?
  private var _wanListener: WanListener?

  let _log = LogProxy.sharedInstance.log

  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var sharedInstance = Discovery()
  private init() {}

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func startLanListener() throws {
    guard _lanListener == nil else { return }
    _lanListener = LanListener(self)
    try _lanListener?.start()
  }
  
  public func stopLanListener() {
    guard _lanListener != nil else { return }
    _lanListener?.stop()
    _lanListener = nil
  }

  public func startWanListener(smartlinkEmail: String?, forceLogin: Bool = false) throws {
    guard _wanListener == nil else { return }
    _wanListener = WanListener(self)
    try _wanListener?.start(using: smartlinkEmail, forceLogin: forceLogin)
  }

  public func startWanListener(using loginResult: LoginResult) throws {
    guard _wanListener == nil else { return }
    _wanListener = WanListener(self)
    try _wanListener?.start(using: loginResult )
  }

  public func stopWanListener() {
    guard _wanListener != nil else { return }
    _wanListener?.stop()
    _wanListener = nil
  }

  public func removePackets(ofType source: PacketSource) {
    for packet in packets where packet.source == source {
      packets[id: packet.id] = nil
    }
  }
  
  /// Initiate a smartlink connection to a radio
  /// - Parameters:
  ///   - serialNumber:       the serial number of the Radio
  ///   - holePunchPort:      the negotiated Hole Punch port number
  public func sendWanConnectMessage(for serial: String, holePunchPort: Int) {
    if _wanListener != nil {
      _log("Discovery: SmartLink connect sent to serial \(serial)", .debug, #function, #file, #line)
      // send a command to SmartLink to request a connection to the specified Radio
      _wanListener!.sendTlsCommand("application connect serial=\(serial) hole_punch_port=\(holePunchPort))")
    } else {
      _log("Discovery: NOT connected, unable to send Wan Connect Message", .warning, #function, #file, #line)
    }
  }
  
  /// Disconnect a smartlink Radio
  /// - Parameter serialNumber:         the serial number of the Radio
  public func sendWanDisconnectMessage(for serial: String) {
    if _wanListener != nil {
      _log("Discovery: SmartLink disconnect sent to serial \(serial)", .debug, #function, #file, #line)
      // send a command to SmartLink to request disconnection from the specified Radio
      _wanListener!.sendTlsCommand("application disconnect_users serial=\(serial)")
    } else {
      _log("Discovery:  NOT connected, unable to send Wan Disconnect Message", .warning, #function, #file, #line)
    }
  }
  
  /// Disconnect a single smartlink Client
  /// - Parameters:
  ///   - serialNumber:         the serial number of the Radio
  ///   - handle:               the handle of the Client
  public func sendWanDisconnectClientMessage(for serial: String, handle: Handle) {
    if _wanListener != nil {
      _log("Discovery: SmartLink disconnect sent to serial \(serial), handle \(handle.hex)", .debug, #function, #file, #line)
      // send a command to SmartLink to request disconnection from the specified Radio
      _wanListener!.sendTlsCommand("application disconnect_users serial=\(serial) handle=\(handle.hex)")
    } else {
      _log("Discovery: SmartLink not active, unable to send Disconnect Message", .warning, #function, #file, #line)
    }
  }
  
  /// Send a Test message
  /// - Parameter serial:     radio serial number
  /// - Returns:              success / failure
  public func smartlinkTest(_ serial: String) -> Bool {
    if _wanListener != nil {
      _log("Discovery: smartLink test initiated to serial number: \(serial)", .debug, #function, #file, #line)
      // send a command to SmartLink to test the connection for the specified Radio
      _wanListener!.sendTlsCommand("application test_connection serial=\(serial)")
      return true
    } else {
      _log("Discovery: SmartLink not active, Test message not sent", .warning, #function, #file, #line)
      return false
    }
  }
  
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
        newPacket = parseGuiClients(newPacket)
        let oldPacket = packets[id: knownPacketId]!
        
        // maintain the id from the known packet, update the timestamp
        newPacket.id = knownPacketId
        newPacket.lastSeen = Date()
        // update the known packet
        packets[id: knownPacketId] = newPacket

        // publish and log the packet
        packetPublisher.send(PacketChange(.updated, packet: newPacket))
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
    newPacket = parseGuiClients(newPacket)
    packets.append(newPacket)

    // publish & log
    packetPublisher.send(PacketChange(.added, packet: newPacket))
    _log("Discovery: \(newPacket.source.rawValue) packet added, \(newPacket.serial)", .debug, #function, #file, #line)

    // find, publish & log client additions
    findClientAdditions(in: newPacket)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse the GuiClient CSV fields in a packet
  private func parseGuiClients(_ newPacket: Packet) -> Packet {
    var updatedPacket = newPacket
    
    guard newPacket.guiClientPrograms != "" && newPacket.guiClientStations != "" && newPacket.guiClientHandles != "" else { return newPacket }
    
    let programs  = newPacket.guiClientPrograms.components(separatedBy: ",")
    let stations  = newPacket.guiClientStations.components(separatedBy: ",")
    let handles   = newPacket.guiClientHandles.components(separatedBy: ",")
    let ips       = newPacket.guiClientIps.components(separatedBy: ",")
    
    guard programs.count == handles.count && stations.count == handles.count && ips.count == handles.count else { return newPacket }
    
    for i in 0..<handles.count {
      // valid handle, non-blank other fields?
      if let handle = handles[i].handle, stations[i] != "", programs[i] != "" , ips[i] != "" {
        
        updatedPacket.guiClients.append(
          GuiClient(handle: handle,
                    station: stations[i],
                    program: programs[i],
                    ip: ips[i])
        )
      }
    }
    return updatedPacket
  }
  
  private func findClientAdditions(in newPacket: Packet, from oldPacket: Packet? = nil) {
    
    for guiClient in newPacket.guiClients {
      if oldPacket == nil || oldPacket?.guiClients[id: guiClient.id] == nil {
        
        // publish & log
        clientPublisher.send(ClientChange(.added, client: guiClient))
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
        clientPublisher.send(ClientChange(.deleted, client: guiClient))
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
}
