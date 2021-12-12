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
  
//  func testButtons() {
//    
//  }
  
  func testIntegration() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(
        queue: { self.testScheduler.eraseToAnyScheduler() }
      )
    )
    
    store.send(.onAppear)

//    self.testScheduler.advance(by: 1)
//
//    mockPacketPublisher.send(PacketUpdate(.added, packet: testPacket(), packets: [testPacket()]))
//
//    self.testScheduler.advance(by: 1)

    store.receive( .packetUpdate(testPacketUpdate()) ) {
      $0.packets = [self.testPacket()]
      $0.forceUpdate.toggle()
    }
//    self.testScheduler.advance(by: 1)

//    store.receive( .clientUpdate(testClientUpdate()) ) {
//      $0.forceUpdate.toggle()
//    }

    store.send(.packet(index: 0, action: .buttonTapped(.defaultBox)) ) {
      $0.defaultPacket = 0
    }
    store.receive( .defaultSelected(testPacket()) ) {
      $0.packets[0] = self.testPacket()
    }
    store.send(.packet(index: 0, action: .buttonTapped(.defaultBox)) ) {
      $0.defaultPacket = nil
    }
    store.receive( .defaultSelected(nil) )

    store.send(.buttonTapped(.test))
    store.send(.buttonTapped(.connect))
    store.send(.buttonTapped(.cancel))
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Test effects
  
//  private func testPacketSubscription() -> Effect<PickerAction, Never> {
//    return Effect(value: .packetUpdate(testPacketUpdate()))
//      .delay(for: .milliseconds(1000), scheduler: self.scheduler.eraseToAnyScheduler())
//      .eraseToEffect()
//      .cancellable(id: PacketSubscriptionId())
//  }
//
//  private func testClientSubscription() -> Effect<PickerAction, Never> {
//    return Effect(value: .clientUpdate(testClientUpdate()))
//      .delay(for: .milliseconds(500), scheduler: self.scheduler.eraseToAnyScheduler())
//      .eraseToEffect()
//      .cancellable(id: ClientSubscriptionId())
//  }
  
  private func testPacket() -> Packet {
    var packet = Packet()
    
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
  
//  private func testPackets() -> [Packet] {
//    return [testPacket()]
//  }
//
  private func testPacketUpdate() -> PacketUpdate {
    return PacketUpdate(.added, packet: testPacket(), packets: [testPacket()])
  }
//
//  private func testClientUpdate() -> ClientUpdate {
//    let client = GuiClient(clientHandle: UInt32(2),
//                           station: "iPad",
//                           program: "SmartSDR-iOS")
//
//    return ClientUpdate(.add, client: client)
//  }



  var mockPacketPublisher = PassthroughSubject<PacketUpdate, Never>()
  var mockClientPublisher = PassthroughSubject<ClientUpdate, Never>()

  public func mockDiscoverySubscriptions() -> Effect<PickerAction, Never> {
    
    return
//    Effect.concatenate(
      mockPacketPublisher
        .receive(on: DispatchQueue.main)
        .map { update in .packetUpdate(update) }
        .eraseToEffect()
        .cancellable(id: PacketSubscriptionId())
//      ,
//      mockClientPublisher
//        .receive(on: DispatchQueue.main)
//        .map { update in PickerAction.clientUpdate(update) }
//        .eraseToEffect()
//        .cancellable(id: ClientSubscriptionId())
//    )
  }
}
