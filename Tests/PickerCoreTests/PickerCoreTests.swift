//
//  PickerCoreTests.swift
//
//
//  Created by Douglas Adams on 11/14/21.
//

import PickerCore
import Discovery
import ComposableArchitecture
import XCTest

@testable import PickerCore

class PickerCoreTests: XCTestCase {
  let testListener = Listener()
  let scheduler = DispatchQueue.test
//  let scheduler = DispatchQueue.main
  
  func testIntegration() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(queue: { self.scheduler.eraseToAnyScheduler() },
                                     listenerEffectStart: { self.testListenerEffect() },
                                     packetEffectStart: { _ in self.testPacketEffect(self.testListener) },
                                     guiClientEffectStart: { _ in self.testGuiClientEffect(self.testListener) }
                                    )
    )
    
    store.send(.onAppear)
    
    store.receive( .listenerStarted(testListener) ) {
      $0.listener = self.testListener
    }
    self.scheduler.advance(by: 1.0)
//    _ = XCTWaiter.wait(for: [expectation(description: "Wait for 1 seconds")], timeout: 1.0)

    store.receive( .pickerUpdate(testPacketUpdate()) ) {
      $0.packets = self.testPackets()
      $0.forceUpdate.toggle()
    }
    self.scheduler.advance(by: 0.5)
//    _ = XCTWaiter.wait(for: [expectation(description: "Wait for 0.5 seconds")], timeout: 0.5)

    store.receive( .guiClientUpdate(testGuiClientUpdate()) ) {
      $0.forceUpdate.toggle()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Test effects
  
  private func testListenerEffect() -> Effect<PickerAction, Never> {
    Effect(value: .listenerStarted( testListener ))
  }
  
  private func testPacketEffect(_ listener: Listener) -> Effect<PickerAction, Never> {
    return Effect(value: .pickerUpdate(testPacketUpdate()))
      .delay(for: .milliseconds(1000), scheduler: self.scheduler.eraseToAnyScheduler())
      .eraseToEffect()

  }
  
  private func testGuiClientEffect(_ listener: Listener) -> Effect<PickerAction, Never> {
    return Effect(value: .guiClientUpdate(testGuiClientUpdate()))
      .delay(for: .milliseconds(500), scheduler: self.scheduler.eraseToAnyScheduler())
      .eraseToEffect()
  }
  
  private func testPacket() -> Packet {
    var packet = Packet()
    
    packet.nickname = "Dougs 6500"
    packet.status = "Available"
    packet.serialNumber = "1234-5678-9012-3456"
    packet.publicIp = "10.0.1.200"
    packet.guiClientHandles = "1,2"
    packet.guiClientPrograms = "SmartSDR-Windows,SmartSDR-iOS"
    packet.guiClientStations = "Windows,iPad"
    packet.guiClientHosts = ""
    packet.guiClientIps = "192.168.1.200,192.168.1.201"

    return packet
  }
  
  private func testPackets() -> [Packet] {
    return [testPacket()]
  }
  
  private func testPacketUpdate() -> Listener.PacketUpdate {
//    var packets = [Packet]()
//    var packet = Packet()
//
//    packet.nickname = "Dougs 6500"
//    packet.status = "Available"
//    packet.serialNumber = "1234-5678-9012-3456"
//    packet.publicIp = "10.0.1.200"
//    packet.guiClientHandles = "1,2"
//    packet.guiClientPrograms = "SmartSDR-Windows,SmartSDR-iOS"
//    packet.guiClientStations = "Windows,iPad"
//    packet.guiClientHosts = ""
//    packet.guiClientIps = "192.168.1.200,192.168.1.201"
//
//    packets.append(packet)
    
//    return Listener.PacketUpdate(.added, packet: packet, packets: packets)
    return Listener.PacketUpdate(.added, packet: testPacket(), packets: testPackets())
  }
  
  private func testGuiClientUpdate() -> Listener.ClientUpdate {
    let client = GuiClient(clientHandle: UInt32(2),
                           station: "iPad",
                           program: "SmartSDR-iOS")
    
    return Listener.ClientUpdate(.add, client: client)
  }
}
