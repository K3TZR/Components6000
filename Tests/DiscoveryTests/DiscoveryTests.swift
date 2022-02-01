//
//  DiscoveryTests.swift
//  Components6000/DiscoveryTests
//
//  Created by Douglas Adams on 11/14/21.
//

import XCTest
import ComposableArchitecture
import Combine

import Shared
import Discovery

@testable import Discovery

class DiscoveryTests: XCTestCase {
  let discovery = Discovery.sharedInstance

  // ----------------------------------------------------------------------------
  // MARK: - testPackets

  func testLiveRadio() {
    var cancellable: AnyCancellable?
    var updates = [PacketChange]()

    cancellable = discovery.packetPublisher
      .sink { update in
        updates.append(update)
      }

    var livePacket = Packet()

    livePacket.callsign = "K3TZR"
    livePacket.model = "FLEX-6500"
    livePacket.nickname = "DougsFlex"
    livePacket.serial = "1715-4055-6500-9722"
    livePacket.status = "Available"
    
    do {
      try discovery.startLanListener()
    } catch LanListenerError.kSocketError {
      XCTFail("Failed to start Lan Listener, Failed to open a socket")
    } catch LanListenerError.kReceivingError {
      XCTFail("Failed to start Lan Listener, Failed to start receiving")
    } catch {
      XCTFail("Failed to start Lan Listener, unknown error")
    }

    sleep(2)

    var result = [
      PacketChange( .added, packet: livePacket )
    ]

    XCTAssert(updates.count >= 1, "Failed to receive Local Packet update(s)")

    for update in updates where update.packet.source == .local{
      XCTAssert( update.packet.serial == result[0].packet.serial, "Local Serial mismatch, \(update.packet.serial ) != \(result[0].packet.serial)" )
      XCTAssert( update.packet.nickname == result[0].packet.nickname, "Local Nickname mismatch, \(update.packet.nickname ) != \(result[0].packet.nickname)" )
      XCTAssert( update.packet.model == result[0].packet.model, "Local Model mismatch, \(update.packet.model ) != \(result[0].packet.model)" )
      XCTAssert( update.packet.callsign == result[0].packet.callsign, "Local Callsign mismatch, \(update.packet.callsign ) != \(result[0].packet.callsign)" )
      XCTAssert( update.packet.status == result[0].packet.status, "Local Status mismatch, \(update.packet.status ) != \(result[0].packet.status)" )
    }

//    do {
//      try discovery.startWanListener(smartlinkEmail: "douglas.adams@me.com")
//    } catch WanListenerError.kFailedToObtainIdToken {
//      XCTFail("Failed to start Wan Listener, Failed To Obtain IdToken")
//    } catch WanListenerError.kFailedToConnect {
//      XCTFail("Failed to start Wan Listener, Failed To Connect")
//    } catch {
//      XCTFail("Failed to start Wan Listener, unknown error")
//    }

//    do {
//      try discovery.startWanListener(using: "douglas.adams@me.com")
//    } catch WanListenerError.kFailedToObtainIdToken {
//      XCTFail("Failed to start Wan Listener, Failed to Obtain IdToken")
//    } catch WanListenerError.kFailedToConnect {
//      XCTFail("Failed to start Wan Listener, Failed to Connect")
//    } catch {
//      XCTFail("Failed to start Wan Listener, unknown error")
//    }

    sleep(2)

    result = [
      PacketChange( .added, packet: livePacket )
    ]
    
    XCTAssert(updates.count >= 2, "Failed to receive Smartlink Packet update(s)")

    for update in updates where update.packet.source == .smartlink {
      XCTAssert( update.packet.serial == result[0].packet.serial, "Smartlink Serial mismatch, \(update.packet.serial ) != \(result[0].packet.serial)" )
      XCTAssert( update.packet.nickname == result[0].packet.nickname, "Smartlink Nickname mismatch, \(update.packet.nickname ) != \(result[0].packet.nickname)" )
      XCTAssert( update.packet.model == result[0].packet.model, "Smartlink Model mismatch, \(update.packet.model ) != \(result[0].packet.model)" )
      XCTAssert( update.packet.callsign == result[0].packet.callsign, "Smartlink Callsign mismatch, \(update.packet.callsign ) != \(result[0].packet.callsign)" )
      XCTAssert( update.packet.status == result[0].packet.status, "Smartlink Status mismatch, \(update.packet.status ) != \(result[0].packet.status)" )
    }

    cancellable?.cancel()
    discovery.packets = IdentifiedArrayOf<Packet>()
  }
  
  func testPackets() {
    let discovery = Discovery.sharedInstance
    var cancellable: AnyCancellable?
    var updates = [PacketChange]()
    
    cancellable = discovery.packetPublisher
      .sink { update in
        updates.append(update)
      }

    var testPacket = Packet()
    
    testPacket.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    testPacket.nickname = "Dougs 6500"
    testPacket.status = "Available"
    testPacket.serial = "1234-5678-9012-3456"
    testPacket.publicIp = "10.0.1.200"
    testPacket.guiClientHandles = "1,2"
    testPacket.guiClientPrograms = "SmartSDR-Windows,SmartSDR-iOS"
    testPacket.guiClientStations = "Windows,iPad"
    testPacket.guiClientHosts = ""
    testPacket.guiClientIps = "192.168.1.200,192.168.1.201"

    // process a Packet
    discovery.processPacket(testPacket)

    XCTAssert( discovery.packets == [testPacket] )

    // process the same Packet a second time but with a different id
    testPacket.id = UUID(uuidString: "00000000-9999-0000-0000-000000000000")!
    discovery.processPacket(testPacket)

    XCTAssert( discovery.packets == [testPacket] )

    // process the original Packet with a change
    testPacket.nickname = "Harrys 6300"
    discovery.processPacket(testPacket)

    XCTAssert( discovery.packets == [testPacket] )

    // process a different Packet
    var testPacket2 = Packet()

    testPacket2.id = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    testPacket2.nickname = "Petes 6700"
    testPacket2.status = "Available"
    testPacket2.serial = "5678-9012-3456-7890"
    testPacket2.publicIp = "20.0.1.200"
    testPacket2.guiClientHandles = ""
    testPacket2.guiClientPrograms = ""
    testPacket2.guiClientStations = ""
    testPacket2.guiClientHosts = ""
    testPacket2.guiClientIps = ""

    discovery.processPacket(testPacket2)

    XCTAssert( discovery.packets == [testPacket, testPacket2] )

    let result = [
      PacketChange( .added, packet: testPacket ),
      PacketChange( .updated, packet: testPacket ),
      PacketChange( .added, packet: testPacket2 )
    ]

    XCTAssert( updates == result )

    cancellable?.cancel()
    discovery.packets = IdentifiedArrayOf<Packet>()
  }

  // ----------------------------------------------------------------------------
  // MARK: - testGuiClients

  func testGuiClients() {
    let discovery = Discovery.sharedInstance
    var cancellable: AnyCancellable?
    var updates = [ClientChange]()
    
    cancellable = discovery.clientPublisher
      .sink { update in
        updates.append(update)
      }

    var testPacket = Packet()
    
    testPacket.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    testPacket.nickname = "Dougs 6500"
    testPacket.status = "Available"
    testPacket.serial = "1234-5678-9012-3456"
    testPacket.publicIp = "10.0.1.200"
    testPacket.guiClientHandles = ""
    testPacket.guiClientPrograms = ""
    testPacket.guiClientStations = ""
    testPacket.guiClientHosts = ""
    testPacket.guiClientIps = ""

    // process a Packet
    discovery.processPacket( testPacket )

    XCTAssert( discovery.packets == [testPacket], "Packets array incorrect" )
    XCTAssert( discovery.stations.count == 0, "Stations count \(discovery.stations.count) != 0" )

    // add a Client
    let testClient1 = GuiClient(handle: 1,
                                station: "Windows",
                                program: "SmartSDR-Windows",
                                clientId: nil,
                                host: "",
                                ip: "192.168.1.200",
                                isLocalPtt: false,
                                isThisClient: false)
    
    testPacket.guiClientHandles = "1"
    testPacket.guiClientPrograms = "SmartSDR-Windows"
    testPacket.guiClientStations = "Windows"
    testPacket.guiClientHosts = ""
    testPacket.guiClientIps = "192.168.1.200"
    discovery.processPacket(testPacket)
    
    XCTAssert( discovery.packets == [testPacket], "Packets array incorrect" )
    XCTAssert( discovery.stations.count == 1, "Stations count \(discovery.stations.count) != 1" )

    // add a second Client
    let testClient2 = GuiClient(handle: 2,
                                station: "iPad",
                                program: "SmartSDR-iOS",
                                clientId: nil,
                                host: "",
                                ip: "192.168.1.201",
                                isLocalPtt: false,
                                isThisClient: false)
    
    testPacket.guiClientHandles = "1,2"
    testPacket.guiClientPrograms = "SmartSDR-Windows,SmartSDR-iOS"
    testPacket.guiClientStations = "Windows,iPad"
    testPacket.guiClientHosts = ""
    testPacket.guiClientIps = "192.168.1.200,192.168.1.201"
    discovery.processPacket(testPacket)
    
    XCTAssert( discovery.packets == [testPacket], "Packets array incorrect" )
    XCTAssert( discovery.stations.count == 2, "Stations count \(discovery.stations.count) != 2" )

    // delete a client
    testPacket.guiClientHandles = "2"
    testPacket.guiClientPrograms = "SmartSDR-iOS"
    testPacket.guiClientStations = "iPad"
    testPacket.guiClientHosts = ""
    testPacket.guiClientIps = "192.168.1.201"
    discovery.processPacket(testPacket)
    
    XCTAssert( discovery.packets == [testPacket], "Packets array incorrect" )

    let result =
    [
      ClientChange( .added, client: testClient1 ),
      ClientChange( .added, client: testClient2 ),
      ClientChange( .deleted, client: testClient1 )
    ]

    XCTAssert( updates == result, "ClientChange not as expected" )
    XCTAssert( discovery.stations.count == 1, "Stations count \(discovery.stations.count) != 1" )

    cancellable?.cancel()
    discovery.packets = IdentifiedArrayOf<Packet>()
  }
}
