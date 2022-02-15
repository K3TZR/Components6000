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

public func subscribeToDiscoveryPackets() -> Effect<PickerAction, Never> {
  Effect.concatenate(
    Discovery.sharedInstance.packetPublisher
      .receive(on: DispatchQueue.main)
      .map { update in .packetChange(update) }
      .eraseToEffect()
      .cancellable(id: DiscoveryPacketSubscriptionId()),
    
    Discovery.sharedInstance.clientPublisher
      .receive(on: DispatchQueue.main)
      .map { update in .clientChange(update) }
      .eraseToEffect()
      .cancellable(id: DiscoveryClientSubscriptionId())
  )
}

public func subscribeToTestResult() -> Effect<PickerAction, Never> {
  Effect(
    Discovery.sharedInstance.testPublisher
      .receive(on: DispatchQueue.main)
      .map { result in .testResultReceived(result) }
      .eraseToEffect()
      .cancellable(id: TestResultSubscriptionId())
  )
}

public func subscribeToWanStatus() -> Effect<PickerAction, Never> {
  Effect(
    Discovery.sharedInstance.wanStatusPublisher
      .receive(on: DispatchQueue.main)
      .map { status in .wanStatus(status) }
      .eraseToEffect()
      .cancellable(id: WanStatusSubscriptionId())
  )
}
