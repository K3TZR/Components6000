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

    store.receive( .packetUpdate(testPacketUpdate()) ) {
      $0.discovery.packets.collection = [self.testPacket()]
      $0.forceUpdate.toggle()
    }

    store.send(.packet(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, action: .buttonTapped(.defaultBox)) ) {
      $0.defaultPacket = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
    store.receive( .defaultSelected(testPacket()) ) {
      $0.discovery.packets.collection[id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!] = self.testPacket()
    }
    store.send(.packet(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, action: .buttonTapped(.defaultBox)) ) {
      $0.defaultPacket = nil
    }
    store.receive( .defaultSelected(nil) )

    store.send(.buttonTapped(.test))
    store.send(.buttonTapped(.connect))
    store.send(.buttonTapped(.cancel))
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
  
  private func testPacketUpdate() -> PacketUpdate {
    return PacketUpdate(.added, packet: testPacket(), packets: [testPacket()])
  }

  var mockPacketPublisher = PassthroughSubject<PacketUpdate, Never>()
  var mockClientPublisher = PassthroughSubject<ClientUpdate, Never>()

  public func mockDiscoverySubscriptions() -> Effect<PickerAction, Never> {
    return
      mockPacketPublisher
        .receive(on: DispatchQueue.main)
        .map { update in .packetUpdate(update) }
        .eraseToEffect()
        .cancellable(id: PacketSubscriptionId())
  }
}
