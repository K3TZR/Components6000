//
//  PickerEffects.swift
//  Components6000/Picker
//
//  Created by Douglas Adams on 3/21/22.
//

import Foundation
import ComposableArchitecture

import Shared

// ----------------------------------------------------------------------------
// MARK: - Subscriptions to publishers

// cancellation IDs
struct TestSubscriptionId: Hashable {}

func subscribeToTest() -> Effect<PickerAction, Never> {
  Effect(
    PacketCollection.sharedInstance.testPublisher
      .receive(on: DispatchQueue.main)
      .map { result in .testResult(result) }
      .eraseToEffect()
      .cancellable(id: TestSubscriptionId())
  )
}
