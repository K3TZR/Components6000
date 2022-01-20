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
  case selection(PickerSelection?)
}

public struct PacketEnvironment {
}

let packetReducer = Reducer<Packet, PacketAction, PacketEnvironment>
{ state, action, environment in

  return .none
}
//  .debug("PACKET ")
