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
    cycleDelay: String = "0",
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
  public var id = UUID()
  @BindableState public var critical: Bool
  @BindableState public var transientState: Bool
  @BindableState public var physicalState: Bool
  @BindableState public var currentState: Bool
  @BindableState public var name: String
  @BindableState public var cycleDelay: String
  @BindableState public var locked: Bool
  
  public enum CodingKeys: String, CodingKey {
    case critical
    case transientState = "transient_state"
    case physicalState = "physical_state"
    case currentState = "state"
    case name
    case cycleDelay = "cycle_delay"
    case locked
  }
  
  // The Initializer function from Decodable
  public init(from decoder: Decoder) throws {
    // Container
    let values = try decoder.container(keyedBy: CodingKeys.self)
    
    // Normal Decoding
    critical = try values.decode(Bool.self, forKey: .critical)
    transientState = try values.decode(Bool.self, forKey: .transientState)
    physicalState = try values.decode(Bool.self, forKey: .physicalState)
    currentState = try values.decode(Bool.self, forKey: .currentState)
    name = try values.decode(String.self, forKey: .name)
    locked = try values.decode(Bool.self, forKey: .locked)
    
    // Conditional Decoding (handles "null")
    if let cycleDelay = try values.decodeIfPresent(Int.self, forKey: .cycleDelay) {
      self.cycleDelay = String(cycleDelay)
    }else {
      self.cycleDelay = ""
    }
  }
  
}

public enum RelayAction: BindableAction, Equatable {
  case checkBoxToggled
  case textFieldChanged(String)
  case binding(BindingAction<Relay>)
}

public struct RelayEnvironment {}

public let relayReducer = Reducer<Relay, RelayAction, RelayEnvironment> { state, action, _ in

  return .none
}
  .binding()
