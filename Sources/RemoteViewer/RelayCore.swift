//
//  RelayCore.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 2/26/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

public struct Relay: Codable, Equatable, Identifiable {
  
  public init(
    critical: Bool = false,
    transientState: Bool = false,
    physicalState: Bool = false,
    currentState: Bool = false,
    name: String,
    cycleDelay: Int? = 0,
    locked: Bool = false
  ) {
    self.critical = critical
    self.transientState = transientState
    self.physicalState = physicalState
    self.currentState = currentState
    self.name = name
    self.cycleDelay = cycleDelay
    self.locked = locked
  }
  public var id: String { name }
  @BindableState public var critical: Bool
  public var transientState: Bool
  public var physicalState: Bool
  @BindableState public var currentState: Bool
  @BindableState public var name: String
  public var cycleDelay: Int?
  @BindableState public var cycleDelayString: String = ""
  public var locked: Bool
  
  public enum CodingKeys: String, CodingKey {
    case critical
    case transientState = "transient_state"
    case physicalState = "physical_state"
    case currentState = "state"
    case name
    case cycleDelay = "cycle_delay"
    case locked
  }
}

public enum RelayAction: BindableAction, Equatable {
  case checkBoxToggled
  case textFieldChanged(String)
  case binding(BindingAction<Relay>)
}

public struct RelayEnvironment {}

public let relayReducer = Reducer<Relay, RelayAction, RelayEnvironment> { state, action, _ in
//  switch action {
//  case .checkBoxToggled:
//    todo.isComplete.toggle()
//    return .none
//
//  case let .textFieldChanged(description):
//    todo.description = description
//    return .none
//  }
  return .none
}
  .binding()
