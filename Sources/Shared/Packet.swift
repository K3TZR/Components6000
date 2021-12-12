//
//  Packet.swift
//  TestSmartlink/Shared
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation

public enum Source: String {
  case local = "Local"
  case smartlink = "Smartlink"
}

public enum PacketAction {
  case added
  case updated
  case deleted
}

public struct PacketUpdate: Equatable {
  public var action: PacketAction
  public var packet: Packet
  public var packets: [Packet]

  public init(_ action: PacketAction, packet: Packet, packets: [Packet]) {
    self.action = action
    self.packet = packet
    self.packets = packets
  }
}

public struct Packet: Identifiable, Equatable, Hashable {
  
  public init(source: Source = .local) {
    id = UUID()
    lastSeen = Date() // now
    self.source = source
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  // these fields are NOT in the received packet but are in the Packet struct
  public var id: UUID                             //  NOT in received packet
  public var lastSeen: Date                       //  NOT in received packet
  public var source: Source                       //  NOT in received packet
  public var isDefault = false                    //  NOT in received packet
  public var isPortForwardOn = false              //  NOT in received packet
  public var isSelected = false                   //  NOT in received packet
  public var guiClients = GuiClients().collection //  NOT in received packet
  public var localInterfaceIP = ""                //  NOT in received packet
  public var requiresHolePunch = false            //  NOT in received packet

  // PACKET TYPE                                     LAN   WAN

  // these fields in the received packet are copied to the Packet struct
  public var callsign = ""                        //  X     X
  public var guiClientHandles = ""                //  X     X
  public var guiClientPrograms = ""               //  X     X
  public var guiClientStations = ""               //  X     X
  public var guiClientHosts = ""                  //  X     X
  public var guiClientIps = ""                    //  X     X
  public var inUseHost = ""                       //  X     X
  public var inUseIp = ""                         //  X     X
  public var model = ""                           //  X     X
  public var nickname = ""                        //  X     X   in WAN as "radio_name"
  public var port = 0                             //  X
  public var publicIp = ""                        //  X     X   in LAN as "ip"
  public var publicTlsPort: Int?                  //        X
  public var publicUdpPort: Int?                  //        X
  public var publicUpnpTlsPort: Int?              //        X
  public var publicUpnpUdpPort: Int?              //        X
  public var serial = ""                          //  X     X
  public var status = ""                          //  X     X
  public var upnpSupported = false                //        X
  public var version = ""                         //  X     X

  // these fields in the received packet are NOT copied to the Packet struct
//  public var availableClients = 0                 //  X         ignored
//  public var availablePanadapters = 0             //  X         ignored
//  public var availableSlices = 0                  //  X         ignored
//  public var discoveryProtocolVersion = ""        //  X         ignored
//  public var fpcMac = ""                          //  X         ignored
//  public var licensedClients = 0                  //  X         ignored
//  public var maxLicensedVersion = ""              //  X     X   ignored
//  public var maxPanadapters = 0                   //  X         ignored
//  public var maxSlices = 0                        //  X         ignored
//  public var radioLicenseId = ""                  //  X     X   ignored
//  public var requiresAdditionalLicense = false    //  X     X   ignored
//  public var wanConnected = false                 //  X         ignored

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public static func ==(lhs: Packet, rhs: Packet) -> Bool {
    // same serial number
    return lhs.serial == rhs.serial && lhs.publicIp == rhs.publicIp
  }
  
  public func isDifferent(from currentPacket: Packet) -> Bool {
    // status
    guard self.status == currentPacket.status else { return true }
//    guard self.availableClients == currentPacket.availableClients else { return true }
//    guard self.availablePanadapters == currentPacket.availablePanadapters else { return true }
//    guard self.availableSlices == currentPacket.availableSlices else { return true }
    // GuiClient
    guard self.guiClientHandles == currentPacket.guiClientHandles else { return true }
    guard self.guiClientPrograms == currentPacket.guiClientPrograms else { return true }
    guard self.guiClientStations == currentPacket.guiClientStations else { return true }
    guard self.guiClientHosts == currentPacket.guiClientHosts else { return true }
    guard self.guiClientIps == currentPacket.guiClientIps else { return true }
    // networking
    guard self.port == currentPacket.port else { return true }
    guard self.inUseHost == currentPacket.inUseHost else { return true }
    guard self.inUseIp == currentPacket.inUseIp else { return true }
    guard self.publicIp == currentPacket.publicIp else { return true }
    guard self.publicTlsPort == currentPacket.publicTlsPort else { return true }
    guard self.publicUdpPort == currentPacket.publicUdpPort else { return true }
    guard self.publicUpnpTlsPort == currentPacket.publicUpnpTlsPort else { return true }
    guard self.publicUpnpUdpPort == currentPacket.publicUpnpUdpPort else { return true }
    guard self.publicTlsPort == currentPacket.publicTlsPort else { return true }
    // user fields
    guard self.callsign == currentPacket.callsign else { return true }
    guard self.model == currentPacket.model else { return true }
    guard self.nickname == currentPacket.nickname else { return true }
    return false
  }
  
//  public func isSamePacket(as currentPacket: DiscoveryPacket) -> Bool {
//    return self.serialNumber == currentPacket.serialNumber && self.publicIp == currentPacket.publicIp
//  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(publicIp)
  }

  /// Parse the GuiClient CSV fields in a packet
  public mutating func parseGuiClients() -> (additions: [GuiClient], deletions: [GuiClient]) {
    
    guard guiClientPrograms != "" && guiClientStations != "" && guiClientHandles != "" else { return ([GuiClient](), [GuiClient]()) }
    
    let prevGuiClients = guiClients
    
    let programs  = guiClientPrograms.components(separatedBy: ",")
    let stations  = guiClientStations.components(separatedBy: ",")
    let handles   = guiClientHandles.components(separatedBy: ",")
    let hosts     = guiClientHosts.components(separatedBy: ",")
    let ips       = guiClientIps.components(separatedBy: ",")
    
//    guard programs.count == handles.count && stations.count == handles.count && hosts.count == handles.count && ips.count == handles.count else { return guiClients}
    guard programs.count == handles.count && stations.count == handles.count && ips.count == handles.count else { return ([GuiClient](), [GuiClient]()) }

    for i in 0..<handles.count {
      // valid handle, non-blank other fields?
//      if let handle = handles[i].handle, stations[i] != "", programs[i] != "" , hosts[i] != "", ips[i] != "" {
      if let handle = handles[i].handle, stations[i] != "", programs[i] != "" , ips[i] != "" {

        guiClients.append( GuiClient(clientHandle: handle,
                                     station: stations[i],
                                     program: programs[i],
                                     host: hosts[i],
                                     ip: ips[i])
        )
      }
    }
    return ( identifyChanges(prevGuiClients) )
  }

  /// Identify added/deleted GuiClients
  /// - Parameters:
  ///   - prevGuiClients:      previous array of GuiClient
  private func identifyChanges(_ prevGuiClients: [GuiClient]) -> ([GuiClient], [GuiClient]) {
    var additions = [GuiClient]()
    var deletions = [GuiClient]()

    // for each GuiClient in the new packet
    for client in guiClients {
      // was it known?
      if prevGuiClients.firstIndex(where: {$0.clientHandle == client.clientHandle} ) == nil {
        // NO, add it
        additions.append(client)
      }
    }
    // for each GuiClient currently known by the Radio
    for client in guiClients {
      // is it in the new packet?
      if prevGuiClients.firstIndex(where: {$0.clientHandle == client.clientHandle} ) == nil {
        // NO, add it
        deletions.append(client)
      }
    }
    return (additions, deletions)
  }
}
