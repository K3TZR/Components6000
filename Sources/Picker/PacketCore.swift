//
//  PacketCore.swift
//  TestDiscoveryPackage/Picker
//
//  Created by Douglas Adams on 11/19/21.
//

import ComposableArchitecture
import Shared

public enum PacketAction: Equatable {
  case defaultButton
  case packetSelected
}

public struct PacketEnvironment {
}

let packetReducer = Reducer<Packet, PacketAction, PacketEnvironment>
  { state, action, environment in
  
  return .none
  }
//  .debug("PACKET ")
