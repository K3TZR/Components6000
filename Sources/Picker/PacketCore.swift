//
//  PacketCore.swift
//  Components6000/Picker
//
//  Created by Douglas Adams on 11/19/21.
//

import ComposableArchitecture
import Shared

public enum PacketAction: Equatable {
  // UI actions
  case defaultButton
  case selection(Bool, Int?)
}

public struct PacketEnvironment {
}

let packetReducer = Reducer<Packet, PacketAction, PacketEnvironment>
  { state, action, environment in

    switch action {
    case .defaultButton:
      state.isDefault.toggle()
      return .none

    case .selection(_,_):
      // handled downstream
      return .none
    }
  }
//  .debug("PACKET ")
