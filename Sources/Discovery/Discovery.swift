//
//  Discovery.swift
//  Components6000/Discovery
//
//  Created by Douglas Adams on 12/6/21.
//

import Foundation
import Combine
import LogProxy
import Shared
import IdentifiedCollections

public final class Discovery: Equatable, ObservableObject {
  public static func == (lhs: Discovery, rhs: Discovery) -> Bool {
    lhs === rhs
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public var packets = IdentifiedArrayOf<Packet>()
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var clientPublisher = PassthroughSubject<ClientChange, Never>()
  public var packetPublisher = PassthroughSubject<PacketChange, Never>()

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _lanListener: LanListener?
  private var _wanListener: WanListener?
  
  let _log = LogProxy.sharedInstance.publish

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public static var sharedInstance = Discovery()

  private init() {}

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func startListeners(smartlinkEmail: String, appName: String, platform: String) throws {
    try startLanListener()
    try startWanListener(smartlinkEmail: smartlinkEmail, appName: appName, platform: platform)
  }

  public func startLanListener() throws {
    _lanListener = try LanListener(discovery: self)
  }

  public func startWanListener(smartlinkEmail: String, appName: String, platform: String) throws {
    _wanListener = try WanListener(discovery: self, smartlinkEmail: smartlinkEmail, appName: appName, platform: platform)
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
        // YES, parse the GuiClient fields, identify additions
        newPacket = parseGuiClients(newPacket)
        identifyAdditions(in: newPacket, from: packets[id: knownPacketId]!)
        identifyDeletions(in: newPacket, from: packets[id: knownPacketId]!)

        // maintain the id from the known packet, update the timestamp
        // update the known packet
        newPacket.id = knownPacketId
        newPacket.lastSeen = Date()
        // update the known packet
        packets[id: knownPacketId] = newPacket

        // publish and Log
        packetPublisher.send(PacketChange(.updated, packet: newPacket))
        _log(LogEntry("Discovery: packet updated, \(newPacket.serial), \(newPacket.source.rawValue)", .debug, #function, #file, #line))

        return
      
      } else {
        // NO, update the timestamp
        packets[id: knownPacketId]!.lastSeen = Date()
        return
      }
    }
    // NO, not seen before, parse the GuiClient fields
    newPacket = parseGuiClients(newPacket)

    _log(LogEntry("Discovery: packet added, \(newPacket.serial), \(newPacket.source.rawValue)", .debug, #function, #file, #line))

    // add it and publish
    packets.append(newPacket)
    packetPublisher.send(PacketChange(.added, packet: newPacket))
    for client in newPacket.guiClients {
      clientPublisher.send(ClientChange(.added, client: client))
    }
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
          GuiClient(clientHandle: handle,
                    station: stations[i],
                    program: programs[i],
                    ip: ips[i])
        )
      }
    }
    return updatedPacket
  }
  
  private func identifyAdditions(in newPacket: Packet, from oldPacket: Packet) {
    
    for guiClient in newPacket.guiClients {
      if oldPacket.guiClients[id: guiClient.id] == nil {
        clientPublisher.send(ClientChange(.added, client: guiClient))
        _log(LogEntry("Discovery: guiClient added, \(guiClient.station)", .debug, #function, #file, #line))
      }
    }
  }

  private func identifyDeletions(in newPacket: Packet, from oldPacket: Packet) {
    
    for guiClient in oldPacket.guiClients {
      if newPacket.guiClients[id: guiClient.id] == nil {
        clientPublisher.send(ClientChange(.deleted, client: guiClient))
        _log(LogEntry("Discovery: guiClient deleted, \(guiClient.station)", .debug, #function, #file, #line))
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
