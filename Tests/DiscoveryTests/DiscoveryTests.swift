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

  func testPackets() {
    let discovery = Discovery.sharedInstance
    var cancellable: AnyCancellable?
    var updates = [PacketChange]()
    
    cancellable = discovery.packetPublisher
      .sink { update in
//        print("-----> DiscoveryTests: \(update.action), id = \(update.packet.id)")
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
//        print("-----> DiscoveryTests: testGuiClients, \(update.action), station = \(update.client.station)")
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

    XCTAssert( discovery.packets == [testPacket] )

    // add a Client
    let testClient1 = GuiClient(clientHandle: 1,
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
    
    XCTAssert( discovery.packets == [testPacket] )

    // add a second Client
    let testClient2 = GuiClient(clientHandle: 2,
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
    
    XCTAssert( discovery.packets == [testPacket] )

    // delete a client
    testPacket.guiClientHandles = "2"
    testPacket.guiClientPrograms = "SmartSDR-iOS"
    testPacket.guiClientStations = "iPad"
    testPacket.guiClientHosts = ""
    testPacket.guiClientIps = "192.168.1.201"
    discovery.processPacket(testPacket)
    
    XCTAssert( discovery.packets == [testPacket] )

    let result =
    [
      ClientChange( .added, client: testClient1 ),
      ClientChange( .added, client: testClient2 ),
      ClientChange( .deleted, client: testClient1 )
    ]

    XCTAssert( updates == result )
    
    for update in updates {
      print("-----> ", update.action, update.client.station)
    }
    
    cancellable?.cancel()
    discovery.packets = IdentifiedArrayOf<Packet>()
  }
}
