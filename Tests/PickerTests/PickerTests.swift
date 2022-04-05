//
//  PickerTests.swift
//  Components6000/PickerTests
//
//  Created by Douglas Adams on 11/14/21.
//

import XCTest
import ComposableArchitecture
import Combine

import Shared
import PickerView
import LanDiscovery

@testable import PickerView

class PickerTests: XCTestCase {
  let testScheduler = DispatchQueue.test

  var testPacket: Packet {
    var packet = Packet()
    packet.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    packet.nickname = "Dougs 6500"
    packet.status = "Available"
    packet.serial = "1234-5678-9012-3456"
    packet.publicIp = "10.0.1.200"
    packet.guiClientHandles = "1,2"
    packet.guiClientPrograms = "SmartSDR-Windows,SmartSDR-iOS"
    packet.guiClientStations = "Windows,iPad"
    packet.guiClientHosts = ""
    packet.guiClientIps = "192.168.1.200,192.168.1.201"
    return packet
  }

  // ----------------------------------------------------------------------------
  // MARK: - testButtons

//  func testButtons() {
//    let store = TestStore(
//      initialState: .init(),
//      reducer: pickerReducer,
//      environment: PickerEnvironment(
//        queue: { self.testScheduler.eraseToAnyScheduler() },
//        discoveryEffect: mockPacketSubscriptions
//      )
//    )
//
//    store.send(.connectButton( PickerSelection(testPacket, nil)) )
//    // TODO: do connection
//    
//    store.send(.testButton( PickerSelection(testPacket, nil)) )
//    // TODO: do testing
//    
//    store.send(.cancelButton)
//  }

  // ----------------------------------------------------------------------------
  // MARK: - testSubscription

  func testPacketSubscription() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        discoverySubscription: { self.mockSubscribeToDiscoveryPackets() }
      )
    )
    store.send(.onAppear)
    
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
    
    testScheduler.advance()
    // PUBLISH a Packet added
    mockPacketPublisher.send( PacketUpdate(.added, packet: testPacket ))
    
    testScheduler.advance()
    // Receive the added Packet
    store.receive( .packetChangeReceived( PacketUpdate(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
      $0.forceUpdate.toggle()
    }
    store.send(.cancelButton)
  }

  func testClientSubscription() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        discoverySubscription: { self.mockSubscribeToDiscoveryPackets() }
      )
    )
    store.send(.onAppear)
    
    var testPacket = Packet()
    
    testPacket.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    testPacket.nickname = "Dougs 6500"
    testPacket.status = "Available"
    testPacket.serial = "1234-5678-9012-3456"
    testPacket.publicIp = "10.0.1.200"
    
    testScheduler.advance()
    // PUBLISH a Packet added
    mockPacketPublisher.send( PacketUpdate(.added, packet: testPacket ))
    
    testScheduler.advance()
    // Receive the added Packet
    store.receive( .packetChangeReceived( PacketUpdate(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
      $0.forceUpdate.toggle()
    }

    let testGuiClient = GuiClient(handle: 1, station: "Windows", program: "SmartSDR-Windows", clientId: nil, host: "201.0.1.2", ip: "192.168.1.200", isLocalPtt: true, isThisClient: true)

    testPacket.guiClientHandles = "1"
    testPacket.guiClientPrograms = "SmartSDR-Windows"
    testPacket.guiClientStations = "Windows"
    testPacket.guiClientHosts = ""
    testPacket.guiClientIps = "192.168.1.200"

    testScheduler.advance()
    // PUBLISH a client addition
    mockClientPublisher.send( ClientUpdate(.added, client: testGuiClient, source: .local ))
    
    testScheduler.advance()
    // Receive the client update
    store.receive( .clientChangeReceived( ClientUpdate(.added, client: testGuiClient, source: .local ))) {
      $0.discovery.packets = [testPacket]
      $0.discovery.stations = [testPacket]
    }
    store.send(.cancelButton)
  }

  // ----------------------------------------------------------------------------
  // MARK: - testIsKnownPacket

  func testIsKnownPacket() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        discoverySubscription: { self.mockSubscribeToDiscoveryPackets() }
      )
    )
    store.send(.onAppear)

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

    testScheduler.advance()
    // add a Packet
    store.send(.packetChangeReceived( PacketUpdate(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
      $0.forceUpdate.toggle()
    }
    
    testScheduler.advance()
    // send the same Packet
    store.send(.packetChangeReceived( PacketUpdate(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
      $0.forceUpdate.toggle()
    }

    testScheduler.advance()
    // delete a Packet
    store.send(.packetChangeReceived( PacketUpdate(.deleted, packet: testPacket ))) {
      $0.discovery.packets = []
      $0.forceUpdate.toggle()
    }
    store.send(.cancelButton)
  }

  // ----------------------------------------------------------------------------
  // MARK: - testPacketChange

  func testPacketChange() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        discoverySubscription: { self.mockSubscribeToDiscoveryPackets() }
      )
    )
    store.send(.onAppear)

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

    testScheduler.advance()
    // add a Packet
    store.send(.packetChangeReceived( PacketUpdate(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
      $0.forceUpdate.toggle()
    }
    
    testScheduler.advance()
    // update a Packet
    var updatedTestPacket = testPacket
    updatedTestPacket.nickname = "Petes 6700"
    store.send(.packetChangeReceived( PacketUpdate(.updated, packet: updatedTestPacket))) {
      $0.discovery.packets = [updatedTestPacket]
      $0.forceUpdate.toggle()
    }
    
    testScheduler.advance()
    // delete a Packet
    store.send(.packetChangeReceived( PacketUpdate(.deleted, packet: testPacket ))) {
      $0.discovery.packets = []
      $0.forceUpdate.toggle()
    }
    store.send(.cancelButton)
  }

  // ----------------------------------------------------------------------------
  // MARK: - testClientChange

  func testClientChange() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        discoverySubscription: { self.mockSubscribeToDiscoveryPackets() }
      )
    )
    store.send(.onAppear)

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

    testScheduler.advance()
    // add a Packet
    store.send(.packetChangeReceived( PacketUpdate(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
      $0.forceUpdate.toggle()
    }
    
    let testClient1 = GuiClient(handle: 1,
                                station: "Windows",
                                program: "SmartSDR-Windows",
                                clientId: nil,
                                host: "",
                                ip: "10.0.1.2",
                                isLocalPtt: false,
                                isThisClient: false)

    testScheduler.advance()
    // add a Client
    store.send(.clientChangeReceived( ClientUpdate(.added, client: testClient1, source: .local ))) {
      var updatedPacket = testPacket
      updatedPacket.guiClientHandles = "1"
      updatedPacket.guiClientPrograms = "SmartSDR-Windows"
      updatedPacket.guiClientStations = "Windows"
      updatedPacket.guiClientHosts = ""
      updatedPacket.guiClientIps = "10.0.1.2"
      $0.discovery.packets = [updatedPacket]
    }
    
    let testClient2 = GuiClient(handle: 2,
                                station: "iPad",
                                program: "SmartSDR-iOS",
                                clientId: nil,
                                host: "",
                                ip: "10.0.1.20",
                                isLocalPtt: false,
                                isThisClient: false)
    
    testScheduler.advance()
    // add a second Client
    store.send(.clientChangeReceived( ClientUpdate(.added, client: testClient2, source: .local ))) {
      var updatedPacket = testPacket
      updatedPacket.guiClientHandles = "1,2"
      updatedPacket.guiClientPrograms = "SmartSDR-Windows,SmartSDR-iOS"
      updatedPacket.guiClientStations = "Windows,iPad"
      updatedPacket.guiClientHosts = ""
      updatedPacket.guiClientIps = "10.0.1.2,10.0.1.20"
      $0.discovery.packets = [updatedPacket]
    }
    
    testScheduler.advance()
    // remove the first Client
    store.send(.clientChangeReceived( ClientUpdate(.deleted, client: testClient1, source: .local ))) {
      var updatedPacket = testPacket
      updatedPacket.guiClientHandles = "2"
      updatedPacket.guiClientPrograms = "SmartSDR-iOS"
      updatedPacket.guiClientStations = "iPad"
      updatedPacket.guiClientHosts = ""
      updatedPacket.guiClientIps = "10.0.1.20"
      $0.discovery.packets = [updatedPacket]
    }
    
    testScheduler.advance()
    // delete the Packet
    store.send(.packetChangeReceived( PacketUpdate(.deleted, packet: testPacket ))) {
      $0.discovery.packets = []
      $0.forceUpdate.toggle()
    }
    store.send(.cancelButton)
  }

  // ----------------------------------------------------------------------------
  // MARK: - testDefault

  func testDefault() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        discoverySubscription: { self.mockSubscribeToDiscoveryPackets() }
      )
    )
    // ON APPEAR
    store.send(.onAppear)
    
    testScheduler.advance()
    // add a Packet
    store.send(.packetChangeReceived( PacketUpdate(.added, packet: testPacket ))) {
      $0.discovery.packets = [self.testPacket]
      $0.forceUpdate.toggle()
    }
    
    testScheduler.advance()
    // Tap the Packet to make it the Default
    store.send(.defaultButton( PickerSelection(testPacket, nil)) ) {
      $0.defaultSelection = PickerSelection(self.testPacket, nil)
    }

    testScheduler.advance()
    // Tap the Packet again to undo it's Default status
    store.send(.defaultButton( PickerSelection(testPacket, nil)) ) {
      $0.defaultSelection = nil
    }
    
    store.send(.cancelButton)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Test related

  var mockPacketPublisher = PassthroughSubject<PacketUpdate, Never>()
  var mockClientPublisher = PassthroughSubject<ClientUpdate, Never>()

  public func mockSubscribeToDiscoveryPackets() -> Effect<PickerAction, Never> {
    Effect.merge(
      mockPacketPublisher
        .receive(on: testScheduler)
        .map { change in .packetChangeReceived(change) }
        .eraseToEffect()
        .cancellable(id: DiscoveryPacketSubscriptionId()),
      
      mockClientPublisher
        .receive(on: testScheduler)
        .map { change in .clientChangeReceived(change) }
        .eraseToEffect()
        .cancellable(id: DiscoveryClientSubscriptionId())
    )
  }

}
