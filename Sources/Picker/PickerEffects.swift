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

private var listener = Listener()

public func packetsSubscription() -> Effect<PickerAction, Never> {
  return listener.packetPublisher
    .receive(on: DispatchQueue.main)
    .map { update in .packetsUpdate(update) }
    .eraseToEffect()
    .cancellable(id: PacketsSubscriptionId())
}


//public func testPacketsSubscription() -> Effect<PickerAction, Never> {
//  return listener.packetPublisher
//    .receive(on: DispatchQueue.main)
//    .map { update in .packetsUpdate(update) }
//    .eraseToEffect()
//    .cancellable(id: PacketsSubscriptionId())
//}








public func clientsSubscription() -> Effect<PickerAction,Never> {
  return listener.clientPublisher
    .receive(on: DispatchQueue.main)
    .map { update in PickerAction.clientsUpdate(update) }
    .eraseToEffect()
    .cancellable(id: ClientsSubscriptionId())
}

//public func testClientsSubscription() -> Effect<PickerAction,Never> {
//  return listener.clientPublisher
//    .receive(on: DispatchQueue.main)
//    .map { update in PickerAction.clientsUpdate(update) }
//    .eraseToEffect()
//    .cancellable(id: ClientsSubscriptionId())
//}
