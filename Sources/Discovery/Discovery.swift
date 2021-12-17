//
//  Discovery.swift
//  TestSmartlink
//
//  Created by Douglas Adams on 12/6/21.
//

import Foundation
import Combine
import LogProxy
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
  
  public var clientPublisher = PassthroughSubject<ClientChange, Never>()
//  public var logPublisher = PassthroughSubject<LogEntry, Never>()
  public var packetPublisher = PassthroughSubject<PacketChange, Never>()

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _lanListener: LanListener?
//  private var _logCancellable: AnyCancellable?
  private var _wanListener: WanListener?
  
  let _log = LogProxy.sharedInstance.publish

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public static var sharedInstance = Discovery()

  private init() {
//    _logCancellable = logPublisher
//      .sink { logEntry in
//        print("Discovery: \(logEntry.message), level = \(logEntry.logLevel.rawValue)")
//      }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func startListeners(smartlinkEmail: String, appName: String, platform: String) throws {
    _lanListener = try LanListener(discovery: self)
    _wanListener = try WanListener(discovery: self, smartlinkEmail: smartlinkEmail, appName: appName, platform: platform)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Process an incoming DiscoveryPacket
  /// - Parameter newPacket: the packet
  func processPacket(_ packet: Packet) {
    var newPacket: Packet
    var prevPacket: Packet

    newPacket = packet
    
    // is it a Packet that has been seen previously?
    if let id = packets.isKnownRadio(newPacket) {
      prevPacket = packets.collection[id: id]!
      
      // YES, known packet, has it changed?
      if newPacket.isDifferent(from: prevPacket) {
        
        _log(LogEntry("Discovery: packet updated, \(newPacket.serial), \(newPacket.source.rawValue)", .debug, #function, #file, #line))

        // YES, changed, parse its GuiClients
        let (additions, deletions) = newPacket.parseGuiClients()

        // update it and publish
        packets.update(newPacket)
        packetPublisher.send(PacketChange(.updated, packet: newPacket, packets: packets.collection))
        for client in additions {
          clientPublisher.send(ClientChange(.add, client: client))
        }
        for client in deletions {
          clientPublisher.send(ClientChange(.delete, client: client))
        }
        return

      } else {
        // NO, same as previous packet, no action
        return
      }
    }
    // NO, not seen previously, parse its GuiClients
    _ = newPacket.parseGuiClients()

    _log(LogEntry("Discovery: packet added, \(newPacket.serial), \(newPacket.source.rawValue)", .debug, #function, #file, #line))

    // add it and publish
    packets.add(newPacket)
    packetPublisher.send(PacketChange(.added, packet: newPacket, packets: packets.collection))
    for client in newPacket.guiClients {
      clientPublisher.send(ClientChange(.add, client: client))
    }
  }
}
