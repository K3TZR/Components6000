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
  
  func testIntegration() {
    let store = TestStore(
      initialState: .init(),
      reducer: pickerReducer,
      environment: PickerEnvironment(queue: { .main },
                                     listenerEffectStart: { self.testListenerEffect() },
                                     packetEffectStart: { _ in self.testPacketEffect(self.testListener) },
                                     guiClientEffectStart: { _ in self.testGuiClientEffect(self.testListener) }
                                    )
    )
    
    store.send(.onAppear)
    
    store.receive( .listenerStarted(testListener) ) {
      $0.listener = self.testListener
    }
    
    store.receive( .pickerUpdate(testPacketUpdate()) ) {
      $0.packets = self.testPackets()
      $0.forceUpdate.toggle()
    }
    
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
    Effect(value: .pickerUpdate(testPacketUpdate()))
  }
  
  private func testGuiClientEffect(_ listener: Listener) -> Effect<PickerAction, Never> {
    Effect(value: .guiClientUpdate(testGuiClientUpdate()))
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
