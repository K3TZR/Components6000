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
  case station = "Station"
  case radio = "Radio"
}

public enum PickerButton: Equatable {
  case test
  case cancel
  case connect
}

public struct PickerState: Equatable {
  public init(pickType: PickType = .radio,
              selectedPacket: Packet? = nil,
              defaultPacket: Packet? = nil,
              testStatus: Bool = false,
              discovery: Discovery = Discovery.sharedInstance)
  {
    self.defaultPacket = defaultPacket
    self.discovery = discovery
    self.pickType = pickType
    self.selectedPacket = selectedPacket
    self.testStatus = testStatus
  }
  
//  public var connectedPacket: Packet?
  public var defaultPacket: Packet?
  public var discovery: Discovery
  public var pickType: PickType
  public var selectedPacket: Packet?
  public var testStatus = false
  public var forceUpdate = false
}

public enum PickerAction: Equatable {
  case onAppear
  
  // UI controls
  case cancelButton
  case connectButton(Packet?)
  case testButton(Packet?)

  // effect related
  case clientChange(ClientChange)
  case connectResultReceived(Int?)
  case packetChange(PacketChange)
  case testResultReceived(Bool)
  case defaultChanged(Packet)
  
  // upstream actions
  case packet(id: UUID, action: PacketAction)
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
      
      // ----------------------------------------------------------------------------
      // MARK: - UI actions

    case .cancelButton:
      // FIXME: probably should not do this here
      // stop listening for Discovery broadcasts (long-running Effect)
      return .cancel(ids: PacketSubscriptionId(), ClientSubscriptionId())

    case .connectButton(_):
      // handled downstream
      return .none

    case .onAppear:
      // FIXME: probably should not do this here
      // start listening for Discovery broadcasts (long-running Effect)
      return environment.subscriptions()
      
    case .testButton(_):
      // handled downstream
      return .none
      
    case .defaultChanged(_):
      // handled downstream
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Effect actions

    case let .clientChange(update):
      // process a GuiClient change
      return .none
      
    case let .connectResultReceived(result):
      // TODO
      return .none
      
    case let .packetChange(update):
      // process a DiscoveryPacket change
      state.forceUpdate.toggle()
      return .none
      
    case let .testResultReceived(result):
      // TODO: Bool versus actual test results???
      state.testStatus = result
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Radio actions

    case let .packet(id: id, action: .defaultButton):
        let thisPacket = state.discovery.packets[id: id]!
        if thisPacket.isDefault {
          for packet in state.discovery.packets where packet.id != thisPacket.id {
            state.discovery.packets[id: packet.id]!.isDefault = false
          }
        }
      return Effect(value: .defaultChanged(thisPacket))

    case let .packet(id: id, action: .selection(value)):
      if value {
        state.selectedPacket = state.discovery.packets[id: id]
      } else {
        state.selectedPacket = nil
      }
      return .none
    }
  }
)
//  .debug("PICKER ")
