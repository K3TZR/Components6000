//
//  RadioPacketCore.swift
//  Components6000/Picker
//
//  Created by Douglas Adams on 11/19/21.
//

import ComposableArchitecture
import Shared

public enum RadioPacketAction: Equatable {
  // UI actions
  case defaultButton
  case selection(Bool)
}

public struct RadioPacketEnvironment {
}

let radioPacketReducer = Reducer<Packet, RadioPacketAction, RadioPacketEnvironment>
  { state, action, environment in

    switch action {
    case .defaultButton:
      state.isDefault.toggle()
      return .none

    case .selection(_):
      // handled downstream
      return .none
    }
  }
//  .debug("PACKET ")
