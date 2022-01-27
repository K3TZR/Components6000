//
//  PickerEffects.swift
//  Components6000/Picker
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

public func liveDiscoveryEffect() -> Effect<PickerAction, Never> {
  
  return Effect.concatenate(
    Discovery.sharedInstance.packetPublisher
      .receive(on: DispatchQueue.main)
      .map { update in .packetChange(update) }
      .eraseToEffect()
      .cancellable(id: PacketEffectId()),
    
    Discovery.sharedInstance.clientPublisher
      .receive(on: DispatchQueue.main)
      .map { update in .clientChange(update) }
      .eraseToEffect()
      .cancellable(id: ClientEffectId())
  )
}

public func TestEffect() -> Effect<PickerAction, Never> {
  
  Effect(
    Discovery.sharedInstance.testPublisher
      .receive(on: DispatchQueue.main)
      .map { result in .testResultReceived(result) }
      .eraseToEffect()
      .cancellable(id: TestEffectId())
  )
}
