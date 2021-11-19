//
//  PickerEffects.swift
//  TestDiscoveryPackage/Picker
//
//  Created by Douglas Adams on 11/17/21.
//

import Foundation
import ComposableArchitecture
import Discovery

// ----------------------------------------------------------------------------
// MARK: - Production effects

private let listener = Listener()

public func packetsEffect() -> Effect<PickerAction, Never> {
  return listener.packetPublisher
    .receive(on: DispatchQueue.main)
    .map { update in .packetsUpdate(update) }
    .eraseToEffect()
    .cancellable(id: PacketPublisherId())
}

public func clientsEffect() -> Effect<PickerAction,Never> {
  return listener.clientPublisher
    .receive(on: DispatchQueue.main)
    .map { update in PickerAction.clientsUpdate(update) }
    .eraseToEffect()
    .cancellable(id: ClientPublisherId())
}

// TODO: Where is this publisher?
//public func testEffect(_ packet: Packet) -> Effect<PickerAction,Never> {
//  return listener.testPublisher
//    .receive(on: DispatchQueue.main)
//    .map { result in PickerAction.testResultReceived(result) }
//    .eraseToEffect()
//    .cancellable(id: TestPublisherId())
//}

// TODO: Where is this publisher?
//public func connectEffect(_ packet: Packet) -> Effect<PickerAction,Never> {
//  return listener.testPublisher
//    .receive(on: DispatchQueue.main)
//    .map { result in PickerAction.connectResultReceived(result) }
//    .eraseToEffect()
//    .cancellable(id: ConnectPublisherId())
//}
