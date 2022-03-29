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
    status: Bool = false,
    name: String,
    locked: Bool = false
  ) {
    self.status = status
    self.name = name
    self.locked = locked
  }
  public var id = UUID()
  public var status: Bool
  @BindableState public var name: String
  public var locked: Bool
  
  public enum CodingKeys: String, CodingKey {
    case status = "physical_state"
    case name
    case locked
  }
}

public enum RelayAction: BindableAction, Equatable {
  case binding(BindingAction<Relay>)
  case toggleStatus
  case nameChanged
}

public struct RelayEnvironment {}

public let relayReducer = Reducer<Relay, RelayAction, RelayEnvironment> { state, action, _ in

  return .none
}
  .binding()
