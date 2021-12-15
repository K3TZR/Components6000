//
//  PickerCore.swift
//  TestDiscoveryPackage/Picker
//
//  Created by Douglas Adams on 11/13/21.
//

import Combine
import ComposableArchitecture
import Dispatch

import Discovery
import Shared
import CloudKit

public enum PickType: String, Equatable {
  case station = "STATION"
  case radio = "RADIO"
}

public enum PickerButton: Equatable {
  case test
  case cancel
  case connect
}

public struct PickerState: Equatable {
  public init(pickType: PickType = .radio,
              selectedPacket: UUID? = nil,
              defaultPacket: UUID? = nil,
              connectedPacket: UUID? = nil,
              forceUpdate: Bool = false,
              testStatus: Bool = false,
              discovery: Discovery = Discovery.sharedInstance)
  {
    self.pickType = pickType
    self.selectedPacket = selectedPacket
    self.defaultPacket = defaultPacket
    self.connectedPacket = connectedPacket
    self.forceUpdate = forceUpdate
    self.testStatus = testStatus
    self.discovery = discovery
  }
  
  public var pickType: PickType
  public var selectedPacket: UUID?
  public var defaultPacket: UUID?
  public var connectedPacket: UUID?
  public var forceUpdate = false
  public var testStatus = false
  public var discovery: Discovery
}

public enum PickerAction: Equatable {
  case onAppear
  
  // buttons
  case buttonTapped(PickerButton)
  
  // effects
  case testResultReceived(Bool)
  case connectResultReceived(Int?)
  
  // subscriptions
  case packetUpdate(PacketUpdate)
  case clientUpdate(ClientUpdate)
  case packet(id: UUID, action: PacketAction)
  case defaultSelected(Packet?)
}

public struct PickerEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
    subscriptions: @escaping () -> Effect<PickerAction, Never> = discoverySubscriptions
  )
  {
    self.queue = queue
    self.subscriptions = subscriptions
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
  var subscriptions: () -> Effect<PickerAction, Never>
}

public let pickerReducer = Reducer<PickerState, PickerAction, PickerEnvironment>.combine(
  packetReducer.forEach(
    state: \PickerState.discovery.packets.collection,
    action: /PickerAction.packet(id:action:),
    environment: { _ in PacketEnvironment() }
      ),
//  packetReducer.forEach(
//    state: \PickerState.discovery.packets.collection,
//    action: /PickerAction.packet(index:action:),
//    environment: { _ in PacketEnvironment() }
//  ),
  Reducer { state, action, environment in
    switch action {
    case .onAppear:
      // start listening for Discovery broadcasts (long-running Effect)
      return environment.subscriptions()
      
    case let .buttonTapped(button):
      switch button {
      case .test:
        // TODO
        print("-----> PickerCore: NOT IMPLEMENTED \(action)")
        return .none
      
      case .cancel:
        return .cancel(ids: PacketSubscriptionId(), ClientSubscriptionId())
      
      case .connect:
        // TODO
        print("-----> PickerCore: NOT IMPLEMENTED \(action)")
        return .none
      }
      
    case let .packetUpdate(update):
      // process a DiscoveryPacket change
      state.discovery.packets.collection = update.packets
      state.forceUpdate.toggle()
      return .none
      
    case let .clientUpdate(update):
      // process a GuiClient change
      state.forceUpdate.toggle()
      return .none
      
    case let .testResultReceived(result):
      // TODO: Bool versus actual test results???
      state.testStatus = result
      return .none
      
    case let .defaultSelected(packet):
      return .none

    case let .packet(id: id, action: .packetTapped):
      state.discovery.packets.collection[id: id]?.isSelected.toggle()
      for packet in state.discovery.packets.collection where packet.id != id {
        state.discovery.packets.collection[id: id]?.isSelected = false
      }
      if state.discovery.packets.collection[id: id]?.isSelected == nil {
        state.selectedPacket = id
      } else {
        state.selectedPacket = nil
      }
      state.forceUpdate.toggle()
      return .none
 
    case let .packet(id: id, action: .buttonTapped(.defaultBox)):
      state.discovery.packets.collection[id: id]?.isDefault.toggle()
      for packet in state.discovery.packets.collection where packet.id != id {
        state.discovery.packets.collection[id: id]?.isDefault = false
      }
      if state.discovery.packets.collection[id: id]?.isDefault == nil {
        state.defaultPacket = id
        return Effect(value: .defaultSelected(state.discovery.packets.collection[id: id]))
      } else {
        state.defaultPacket = nil
        return Effect(value: .defaultSelected(nil))
      }

    case let .packet(id: id, action: action):
      state.forceUpdate.toggle()
      return .none
    
    case let .connectResultReceived(result):
      // TODO
      print("-----> PickerCore: NOT IMPLEMENTED \(action)")
      return .none
    }
  }
)
//  .debug("PICKER ")

struct PacketSubscriptionId: Hashable {}
struct ClientSubscriptionId: Hashable {}

