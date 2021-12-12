//
//  DiscoveryParser.swift
//  TestSmartlink
//
//  Created by Douglas Adams on 12/10/21.
//

import Foundation
import Shared

extension Discovery {

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
        logPublisher.send(LogEntry("Unknown Discovery token - \(property.key) = \(property.value)", .warning, #function, #file, #line))
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
      case .publicTlsPort:              packet.publicTlsPort = property.value.iValue
      case .publicUdpPort:              packet.publicUdpPort = property.value.iValue
      case .publicUpnpTlsPort:          packet.publicUpnpTlsPort = property.value.iValue
      case .publicUpnpUdpPort:          packet.publicUpnpUdpPort = property.value.iValue
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
