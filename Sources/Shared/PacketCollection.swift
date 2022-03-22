//
//  Packets.swift
//  Components6000/Shared
//
//  Created by Douglas Adams on 3/20/22.
//

import Foundation
import Combine
import IdentifiedCollections

public final class PacketCollection: Equatable, ObservableObject {
  public static func == (lhs: PacketCollection, rhs: PacketCollection) -> Bool {
    lhs === rhs
  }

  // ----------------------------------------------------------------------------
  // MARK: - Publishers
  
  public var clientPublisher = PassthroughSubject<ClientUpdate, Never>()
  public var packetPublisher = PassthroughSubject<PacketUpdate, Never>()
  public var testPublisher = PassthroughSubject<SmartlinkTestResult, Never>()
  public var wanStatusPublisher = PassthroughSubject<WanStatus, Never>()
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var packets = IdentifiedArrayOf<Packet>()
  public var stations = IdentifiedArrayOf<Packet>()

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  let _log = LogProxy.sharedInstance.log

  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var sharedInstance = PacketCollection()
  private init() {}

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Process an incoming DiscoveryPacket
  /// - Parameter newPacket: the packet
  public func processPacket(_ packet: Packet) {
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
        _log("PacketCollection: \(newPacket.source.rawValue) packet updated, \(newPacket.serial)", .debug, #function, #file, #line)

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
    _log("PacketCollection: \(newPacket.source.rawValue) packet added, \(newPacket.serial)", .debug, #function, #file, #line)

    // find, publish & log client additions
    findClientAdditions(in: newPacket)
  }

  public func removePackets(ofType source: PacketSource) {
    for packet in packets where packet.source == source {
      packets[id: packet.id] = nil
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func findClientAdditions(in newPacket: Packet, from oldPacket: Packet? = nil) {
    
    for guiClient in newPacket.guiClients {
      if oldPacket == nil || oldPacket?.guiClients[id: guiClient.id] == nil {
        
        // publish & log
        clientPublisher.send(ClientUpdate(.added, client: guiClient, source: newPacket.source))
        _log("PacketCollection: \(newPacket.source.rawValue) guiClient added, \(guiClient.station)", .debug, #function, #file, #line)
        
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
        _log("PacketCollection: \(newPacket.source.rawValue) guiClient deleted, \(guiClient.station)", .debug, #function, #file, #line)
        
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
