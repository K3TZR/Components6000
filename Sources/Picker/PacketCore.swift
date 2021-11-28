//
//  PacketCore.swift
//  TestDiscoveryPackage/Picker
//
//  Created by Douglas Adams on 11/19/21.
//

import ComposableArchitecture
import Shared

public enum PacketAction {
  case defaultButtonClicked
  case packetSelected
}

public struct PacketEnvironment {
}

let packetReducer = Reducer<Packet, PacketAction, PacketEnvironment> {
  state, action, environment in

  switch action {

  case .defaultButtonClicked:
    print("PacketCore: .defaultButtonClicked")
    state.isDefault.toggle()
    return .none

  case .packetSelected:
    print("PacketCore: .packetSelected")
    state.isSelected.toggle()
    return .none
  }
}
//  .debug()
