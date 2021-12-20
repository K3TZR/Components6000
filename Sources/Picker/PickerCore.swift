//
//  PickerCore.swift
//  Components6000/Picker
//
//  Created by Douglas Adams on 11/13/21.
//

import Combine
import ComposableArchitecture
import Dispatch

import Discovery
import Shared

struct PacketSubscriptionId: Hashable {}
struct ClientSubscriptionId: Hashable {}

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
  case cancelButton
  case connectButton
  case testButton

  // effects
  case testResultReceived(Bool)
  case connectResultReceived(Int?)
  
  // subscriptions
  case packetChange(PacketChange)
  case clientChange(ClientChange)
  case packet(id: UUID, action: PacketAction)
  case defaultSelected(UUID?)
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
    state: \PickerState.discovery.packets,
    action: /PickerAction.packet(id:action:),
    environment: { _ in PacketEnvironment() }
      ),
  Reducer { state, action, environment in
    switch action {

      // ----- Picker level actions -----
    case .onAppear:
      // start listening for Discovery broadcasts (long-running Effect)
      return environment.subscriptions()
      
    case .cancelButton:
      return .cancel(ids: PacketSubscriptionId(), ClientSubscriptionId())

    case .connectButton:
      // TODO
      print("-----> PickerCore: NOT IMPLEMENTED \(action)")
      return .none

    case .testButton:
        // TODO
        print("-----> PickerCore: NOT IMPLEMENTED \(action)")
        return .none
      
    case let .packetChange(update):
      // process a DiscoveryPacket change
      state.discovery.packets[id: update.packet.id] = update.packet
//      state.forceUpdate.toggle()
      return .none
      
    case let .clientChange(update):
      // process a GuiClient change
//      state.forceUpdate.toggle()
      return .none
      
    case let .testResultReceived(result):
      // TODO: Bool versus actual test results???
      state.testStatus = result
      return .none
      
    case let .defaultSelected(id):
      return .none

    case let .connectResultReceived(result):
      // TODO
      return .none

      
      // ----- Packet level actions -----
    case let .packet(id: id, action: .packetSelected):
      
      if var packet = state.discovery.packets[id: id] {
        packet.isSelected.toggle()

        if packet.isSelected {
          state.selectedPacket = packet.id
        } else {
          state.selectedPacket = nil
        }
        state.discovery.packets[id: id]?.isSelected = packet.isSelected
//        state.forceUpdate.toggle()
        return Effect(value: .defaultSelected(state.selectedPacket))

      } else {
        return .none
      }

    case let .packet(id: id, action: .defaultButton):
      
      if var packet = state.discovery.packets[id: id] {
        packet.isDefault.toggle()

        if packet.isDefault {
          state.defaultPacket = packet.id
        } else {
          state.defaultPacket = nil
        }
        state.discovery.packets[id: id]?.isDefault = packet.isDefault
//        state.forceUpdate.toggle()
        return Effect(value: .defaultSelected(state.defaultPacket))

      } else {
        return .none
      }
      
    case let .packet(id: id, action: action):
      return .none    
    }
  }
)
  .debug("PICKER ")
