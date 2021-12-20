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
import Picker
import Discovery

@testable import Picker

class PickerTests: XCTestCase {
  let testScheduler = DispatchQueue.test

  // ----------------------------------------------------------------------------
  // MARK: - testButtons

  func testButtons() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        subscriptions: mockPacketSubscriptions
      )
    )

    store.send(.connectButton)
    // TODO: do connection
    
    store.send(.testButton)
    // TODO: do testing
    
    store.send(.cancelButton)
  }

  // ----------------------------------------------------------------------------
  // MARK: - testSubscription

  func testPacketSubscription() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        subscriptions: mockPacketSubscriptions
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
    mockPacketPublisher.send( PacketChange(.added, packet: testPacket ))
    
    testScheduler.advance()
    // Receive the added Packet
    store.receive( .packetChange( PacketChange(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
//      $0.forceUpdate.toggle()
    }
    store.send(.cancelButton)
  }

  private func testPacket() -> Packet {
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
  // MARK: - testIsKnownPacket

  func testIsKnownPacket() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        subscriptions: mockPacketSubscriptions
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
    store.send(.packetChange( PacketChange(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
    }
    
    testScheduler.advance()
    // send the same Packet
    store.send(.packetChange( PacketChange(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
    }

    testScheduler.advance()
    // delete a Packet
    store.send(.packetChange( PacketChange(.deleted, packet: testPacket ))) {
      $0.discovery.packets = []
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
        subscriptions: mockPacketSubscriptions
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
    store.send(.packetChange( PacketChange(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
    }
    
    testScheduler.advance()
    // update a Packet
    var updatedTestPacket = testPacket
    updatedTestPacket.nickname = "Petes 6700"
    store.send(.packetChange( PacketChange(.updated, packet: updatedTestPacket))) {
      $0.discovery.packets = [updatedTestPacket]
    }
    
    testScheduler.advance()
    // delete a Packet
    store.send(.packetChange( PacketChange(.deleted, packet: testPacket ))) {
      $0.discovery.packets = []
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
        subscriptions: mockClientSubscriptions
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
    store.send(.packetChange( PacketChange(.added, packet: testPacket ))) {
      $0.discovery.packets = [testPacket]
    }
    
    let testClient1 = GuiClient(clientHandle: 1,
                                station: "Windows",
                                program: "SmartSDR-Windows",
                                clientId: nil,
                                host: "",
                                ip: "10.0.1.2",
                                isLocalPtt: false,
                                isThisClient: false)

    testScheduler.advance()
    // add a Client
    store.send(.clientChange( ClientChange(.added, client: testClient1 ))) {
      var updatedPacket = testPacket
      updatedPacket.guiClientHandles = "1"
      updatedPacket.guiClientPrograms = "SmartSDR-Windows"
      updatedPacket.guiClientStations = "Windows"
      updatedPacket.guiClientHosts = ""
      updatedPacket.guiClientIps = "10.0.1.2"
      $0.discovery.packets = [updatedPacket]
    }
    
    let testClient2 = GuiClient(clientHandle: 2,
                                station: "iPad",
                                program: "SmartSDR-iOS",
                                clientId: nil,
                                host: "",
                                ip: "10.0.1.20",
                                isLocalPtt: false,
                                isThisClient: false)
    
    testScheduler.advance()
    // add a second Client
    store.send(.clientChange( ClientChange(.added, client: testClient2 ))) {
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
    store.send(.clientChange( ClientChange(.deleted, client: testClient1 ))) {
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
    store.send(.packetChange( PacketChange(.deleted, packet: testPacket ))) {
      $0.discovery.packets = []
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
        subscriptions: mockPacketSubscriptions
      )
    )
    // ON APPEAR
    store.send(.onAppear)
    
    testScheduler.advance()
    // add a Packet
    store.send(.packetChange( PacketChange(.added, packet: testPacket() ))) {
      $0.discovery.packets = [self.testPacket()]
    }
    
    testScheduler.advance()
    // Tap the Packet to make it the Default
    store.send(.packet(id: self.testPacket().id, action: .defaultButton) ) {
      $0.discovery.packets[id: self.testPacket().id]?.isDefault = true
      $0.defaultPacket = self.testPacket().id
//      $0.forceUpdate.toggle()
    }

    testScheduler.advance()
    // Confirm the Default status
    store.receive( .defaultSelected(self.testPacket().id) ) {
      $0.defaultPacket = self.testPacket().id
    }

    testScheduler.advance()
    // Tap the Packet again to undo it's Default status
    store.send(.packet(id: self.testPacket().id, action: .defaultButton) ) {
      $0.discovery.packets[id: self.testPacket().id]?.isDefault = false
      $0.defaultPacket = nil
//      $0.forceUpdate.toggle()
    }

    testScheduler.advance()
    // Confirm the Default status
    store.receive( .defaultSelected(nil) ) {
      $0.defaultPacket = nil
    }
    store.send(.cancelButton)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Test related

  var mockPacketPublisher = PassthroughSubject<PacketChange, Never>()
  var mockClientPublisher = PassthroughSubject<ClientChange, Never>()

  public func mockPacketSubscriptions() -> Effect<PickerAction, Never> {
    return
      mockPacketPublisher
        .receive(on: testScheduler)
        .map { update in .packetChange(update) }
        .eraseToEffect()
        .cancellable(id: PacketSubscriptionId())
  }
  
  public func mockClientSubscriptions() -> Effect<PickerAction, Never> {
    return
      mockClientPublisher
        .receive(on: testScheduler)
        .map { update in .clientChange(update) }
        .eraseToEffect()
        .cancellable(id: ClientSubscriptionId())
  }

}
