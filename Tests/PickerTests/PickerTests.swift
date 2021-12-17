//
//  PickerTests.swift
//  TestDiscoveryPackage/PickerTests
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
  
  func testButtons() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        subscriptions: mockDiscoverySubscriptions
      )
    )

    store.send(.connectButton)
    // TODO: do connection
    
    store.send(.testButton)
    // TODO: do testing
    
    store.send(.cancelButton)
  }
  
  func testSubscription() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        subscriptions: mockDiscoverySubscriptions
      )
    )
    // ON APPEAR
    store.send(.onAppear)
    
    testScheduler.advance()
    // PUBLISH a Packet added
    mockPacketPublisher.send( PacketChange(.added, packet: testPacket(), packets: [self.testPacket()] ))
    
    testScheduler.advance()
    // Receive the added Packet
    store.receive( .packetChange( PacketChange(.added, packet: testPacket(), packets: [self.testPacket()] ))) {
      $0.discovery.packets.collection = [self.testPacket()]
//      $0.forceUpdate.toggle()
    }
    store.send(.cancelButton)
  }
  
  func testPacketUpdates() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        subscriptions: mockDiscoverySubscriptions
      )
    )
    store.send(.onAppear)

    testScheduler.advance()
    // add a Packet
    store.send(.packetChange( PacketChange(.added, packet: testPacket(), packets: [testPacket()] ))) {
      $0.discovery.packets.collection = [self.testPacket()]
    }
    
    testScheduler.advance()
    // update a Packet
    var updatedTestPacket = testPacket()
    updatedTestPacket.nickname = "Petes 6700"
    store.send(.packetChange( PacketChange(.updated, packet: updatedTestPacket, packets: [updatedTestPacket] ))) {
      $0.discovery.packets.collection = [updatedTestPacket]
    }
    
    testScheduler.advance()
    // delete a Packet
    store.send(.packetChange( PacketChange(.deleted, packet: testPacket(), packets: [self.testPacket()] ))) {
      $0.discovery.packets.collection = []
    }
    store.send(.cancelButton)
  }

  
  func testDefault() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() },
        subscriptions: mockDiscoverySubscriptions
      )
    )
    // ON APPEAR
    store.send(.onAppear)
    
    testScheduler.advance()
    // add a Packet
    store.send(.packetChange( PacketChange(.added, packet: testPacket(), packets: [testPacket()] ))) {
      $0.discovery.packets.collection = [self.testPacket()]
    }
    
    testScheduler.advance()
    // Tap the Packet to make it the Default
    store.send(.packet(id: self.testPacket().id, action: .defaultButton) ) {
      $0.discovery.packets.collection[id: self.testPacket().id]?.isDefault = true
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
      $0.discovery.packets.collection[id: self.testPacket().id]?.isDefault = false
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
  
  private func testPacketAdd() -> PacketChange {
    return PacketChange(.added, packet: testPacket(), packets: [testPacket()])
  }

  private func testPacketUpdate() -> PacketChange {
    var updatedTestPacket = testPacket()
    updatedTestPacket.nickname = "Dougs 6700"
    return PacketChange(.updated, packet: updatedTestPacket, packets: [updatedTestPacket])
  }

  var mockPacketPublisher = PassthroughSubject<PacketChange, Never>()
  var mockClientPublisher = PassthroughSubject<ClientChange, Never>()

  public func mockDiscoverySubscriptions() -> Effect<PickerAction, Never> {
    return
      mockPacketPublisher
        .receive(on: testScheduler)
        .map { update in .packetChange(update) }
        .eraseToEffect()
        .cancellable(id: PacketSubscriptionId())
  }
}
