//
//  PacketCore.swift
//  TestDiscoveryPackage/Picker
//
//  Created by Douglas Adams on 11/19/21.
//

import ComposableArchitecture
import Discovery
import Shared

public enum PacketAction {
  case checkboxTapped
}

public struct PacketEnvironment {
}

let packetReducer = Reducer<Packet, PacketAction, PacketEnvironment> {
  state, action, environment in
  switch action {
  case .checkboxTapped:
    state.isDefault.toggle()
    return .none
  }
}
