//
//  PickerEffects.swift
//  TestDiscoveryPackage/Picker
//
//  Created by Douglas Adams on 11/17/21.
//

import Foundation
import ComposableArchitecture
import Combine

import Discovery
import Shared

// ----------------------------------------------------------------------------
// MARK: - Production effects

public func discoverySubscriptions() -> Effect<PickerAction, Never> {
  
  return Effect.concatenate(
    Discovery.sharedInstance.packetPublisher
      .receive(on: DispatchQueue.main)
      .map { update in .packetUpdate(update) }
      .eraseToEffect()
      .cancellable(id: PacketSubscriptionId()),
    
    Discovery.sharedInstance.clientPublisher
      .receive(on: DispatchQueue.main)
      .map { update in PickerAction.clientUpdate(update) }
      .eraseToEffect()
      .cancellable(id: ClientSubscriptionId())
  )
}
