//
//  Discovery.swift
//  TestSmartlink
//
//  Created by Douglas Adams on 12/6/21.
//

import Foundation
import Combine
import Shared

public final class Discovery: Equatable, ObservableObject {
  public static func == (lhs: Discovery, rhs: Discovery) -> Bool {
    lhs === rhs
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public var packets = Packets()
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var clientPublisher = PassthroughSubject<ClientUpdate, Never>()
  public var logPublisher = PassthroughSubject<LogEntry, Never>()
  public var packetPublisher = PassthroughSubject<PacketUpdate, Never>()

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _lanListener: LanListener?
  private var _logCancellable: AnyCancellable?
  private var _wanListener: WanListener?

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public static var sharedInstance = Discovery()

  private init() {
    _logCancellable = logPublisher
      .sink { logEntry in
        print("Discovery: \(logEntry.message), level = \(logEntry.logLevel.rawValue)")
      }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func startListeners(smartlinkEmail: String, appName: String, platform: String) throws {
    _lanListener = try LanListener(discovery: self)
    _wanListener = try WanListener(discovery: self, smartlinkEmail: smartlinkEmail, appName: appName, platform: platform)
  }

//  public func startLanListener() throws {
//    _lanListener = try LanListener(discovery: self)
//  }
//
//  public func startWanListener(smartlinkEmail: String, appName: String, platform: String ) throws {
//    _wanListener = try WanListener(discovery: self, smartlinkEmail: smartlinkEmail, appName: appName, platform: platform)
//  }

//  public func stopListeners() {
//    _lanListener?.stop()
//    _wanListener?.stop()
//    _lanListener = nil
//    _wanListener = nil
//    packets.removeAll()
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Process an incoming DiscoveryPacket
  /// - Parameter newPacket: the packet
  func processPacket(_ packet: Packet) {
    var newPacket: Packet
    var prevPacket: Packet

    newPacket = packet
    
    // is it a Packet that has been seen previously?
    if let index = packets.isKnownPacket(packet) {
      prevPacket = packets.collection[index]
      
      // YES, known packet, has it changed?
      if newPacket.isDifferent(from: prevPacket) {
        
        logPublisher.send(LogEntry("known packet with changes received, \(newPacket.serial), \(newPacket.source.rawValue)", .debug, #function, #file, #line))

        // YES, changed, parse its GuiClients
        let (additions, deletions) = newPacket.parseGuiClients()

        // update it and publish
        packets.update(newPacket)
        packetPublisher.send(PacketUpdate(.updated, packet: newPacket, packets: packets.collection))
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
    _ = newPacket.parseGuiClients()

    logPublisher.send(LogEntry("new packet received, \(newPacket.serial), \(newPacket.source.rawValue)", .debug, #function, #file, #line))

    // add it and publish
    packets.add(newPacket)
    packetPublisher.send(PacketUpdate(.added, packet: newPacket, packets: packets.collection))
    for client in newPacket.guiClients {
      clientPublisher.send(ClientUpdate(.add, client: client))
    }
  }
}
