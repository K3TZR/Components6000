//
//  PacketCore.swift
//  TestDiscoveryPackage/Picker
//
//  Created by Douglas Adams on 11/19/21.
//

import ComposableArchitecture
import Shared

public enum PacketButton: Equatable {
  case defaultBox
}

public enum PacketAction: Equatable {
  case buttonTapped(PacketButton)
  case packetTapped
}

public struct PacketEnvironment {
}

let packetReducer = Reducer<Packet, PacketAction, PacketEnvironment>
  { state, action, environment in
  
  return .none
  }
  .debug("PACKET ")
