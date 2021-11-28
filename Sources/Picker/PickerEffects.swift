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

public func packetsSubscription(_ listener: Listener) -> Effect<PickerAction, Never> {
  return listener.packetPublisher
    .receive(on: DispatchQueue.main)
    .map { update in .packetsUpdate(update) }
    .eraseToEffect()
    .cancellable(id: PacketsSubscriptionId())
}

public func clientsSubscription(_ listener: Listener) -> Effect<PickerAction,Never> {
  return listener.clientPublisher
    .receive(on: DispatchQueue.main)
    .map { update in PickerAction.clientsUpdate(update) }
    .eraseToEffect()
    .cancellable(id: ClientsSubscriptionId())
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
