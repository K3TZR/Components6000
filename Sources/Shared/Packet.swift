//
//  Packet.swift
//  Components6000/Shared
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import ComposableArchitecture

public enum PacketSource: String, Equatable {
  case local = "Local"
  case smartlink = "Smartlink"
}

public enum PacketState{
  case added
  case deleted
  case updated
}

public struct PacketChange: Equatable {
  public var state: PacketState
  public var packet: Packet

  public init(_ state: PacketState, packet: Packet) {
    self.state = state
    self.packet = packet
  }
}

public struct Packet: Identifiable, Equatable, Hashable {
  
  public init(source: PacketSource = .local) {
    id = UUID()
    lastSeen = Date() // now
    self.source = source
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  // these fields are NOT in the received packet but are in the Packet struct
  public var id: UUID
  public var lastSeen: Date
  public var source: PacketSource
//  public var isDefault = false
  public var isPortForwardOn = false
//  public var isSelected = false
  public var guiClients = IdentifiedArrayOf<GuiClient>()
  public var localInterfaceIP = ""
  public var requiresHolePunch = false
  public var negotiatedHolePunchPort = 0
  public var wanHandle = ""

  // PACKET TYPE                                     LAN   WAN

  // these fields in the received packet ARE COPIED to the Packet struct
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

  // these fields in the received packet ARE NOT COPIED to the Packet struct
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
  
  public func isDifferent(from knownPacket: Packet) -> Bool {
    // status
    guard status == knownPacket.status else { return true }
    //    guard self.availableClients == currentPacket.availableClients else { return true }
    //    guard self.availablePanadapters == currentPacket.availablePanadapters else { return true }
    //    guard self.availableSlices == currentPacket.availableSlices else { return true }
    // GuiClient
    guard self.guiClientHandles == knownPacket.guiClientHandles else { return true }
    guard self.guiClientPrograms == knownPacket.guiClientPrograms else { return true }
    guard self.guiClientStations == knownPacket.guiClientStations else { return true }
    guard self.guiClientHosts == knownPacket.guiClientHosts else { return true }
    guard self.guiClientIps == knownPacket.guiClientIps else { return true }
    // networking
    guard port == knownPacket.port else { return true }
    guard inUseHost == knownPacket.inUseHost else { return true }
    guard inUseIp == knownPacket.inUseIp else { return true }
    guard publicIp == knownPacket.publicIp else { return true }
    guard publicTlsPort == knownPacket.publicTlsPort else { return true }
    guard publicUdpPort == knownPacket.publicUdpPort else { return true }
    guard publicUpnpTlsPort == knownPacket.publicUpnpTlsPort else { return true }
    guard publicUpnpUdpPort == knownPacket.publicUpnpUdpPort else { return true }
    guard publicTlsPort == knownPacket.publicTlsPort else { return true }
    // user fields
    guard callsign == knownPacket.callsign else { return true }
    guard model == knownPacket.model else { return true }
    guard nickname == knownPacket.nickname else { return true }
    return false
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(publicIp)
  }
}
