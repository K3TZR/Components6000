//
//  StationPacketCore.swift
//  Components6000/Picker
//
//  Created by Douglas Adams on 11/19/21.
//

import ComposableArchitecture
import Shared

public enum StationPacketAction: Equatable {
  // UI actions
  case defaultButton
  case selection(Bool)
}

public struct StationPacketEnvironment {
}

let stationPacketReducer = Reducer<Packet, StationPacketAction, StationPacketEnvironment>
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
