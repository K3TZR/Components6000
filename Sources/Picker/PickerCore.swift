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
              packets: [Packet] = [],
              selectedPacket: Int? = nil,
              defaultPacket: Int? = nil,
              connectedPacket: Int? = nil,
              forceUpdate: Bool = false,
              testStatus: Bool = false)
  {
    self.pickType = pickType
    self.packets = packets
    self.selectedPacket = selectedPacket
    self.defaultPacket = defaultPacket
    self.connectedPacket = connectedPacket
    self.forceUpdate = forceUpdate
    self.testStatus = testStatus
  }
  
  public var pickType: PickType = .radio
  public var packets: [Packet] = []
  public var selectedPacket: Int? = nil
  public var defaultPacket: Int? = nil
  public var connectedPacket: Int? = nil
  public var forceUpdate = false
  public var testStatus = false
}

public enum PickerAction: Equatable {
  case onAppear
  
  // buttons
  case buttonTapped(PickerButton)
  
  // effects
  case testResultReceived(Bool)
  case connectResultReceived(Int?)
  
  // subscriptions
  case packetsUpdate(PacketUpdate)
  case clientsUpdate(ClientUpdate)
  case packet(index: Int, action: PacketAction)
  case defaultSelected(Packet?)
}

public struct PickerEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
    packetsEffect: @escaping () -> Effect<PickerAction, Never> = packetsSubscription,
    clientsEffect: @escaping () -> Effect<PickerAction, Never> = clientsSubscription
  )
  {
    self.queue = queue
    self.packetsEffect = packetsEffect
    self.clientsEffect = clientsEffect
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
  var packetsEffect: () -> Effect<PickerAction, Never>
  var clientsEffect: () -> Effect<PickerAction, Never>
}

public let pickerReducer = Reducer<PickerState, PickerAction, PickerEnvironment>.combine(
  packetReducer.forEach(state: \PickerState.packets,
                        action: /PickerAction.packet(index:action:),
                        environment: { _ in PacketEnvironment() }
                       ),
  Reducer { state, action, environment in
    switch action {
    case .onAppear:
      // start listening for Discovery broadcasts
      return .concatenate( environment.packetsEffect(),
                           environment.clientsEffect()
      )
      
    case let .buttonTapped(button):
      switch button {
      case .test:
        // TODO
        print("-----> PickerCore: NOT IMPLEMENTED \(action)")
        return .none
      
      case .cancel:
        return .cancel(ids: PacketsSubscriptionId(), ClientsSubscriptionId())
      
      case .connect:
        // TODO
        print("-----> PickerCore: NOT IMPLEMENTED \(action)")
        return .none
      }
      
    case let .packetsUpdate(update):
      // process a DiscoveryPacket change
      state.packets = update.packets
      state.forceUpdate.toggle()
      return .none
      
    case let .clientsUpdate(update):
      // process a GuiClient change
      state.forceUpdate.toggle()
      return .none
      
    case let .testResultReceived(result):
      // TODO: Bool versus actual test results???
      state.testStatus = result
      return .none
      
    case let .defaultSelected(packet):
      return .none

    case let .packet(index: index, action: .packetTapped):
      state.packets[index].isSelected.toggle()
      for (i, packet) in state.packets.enumerated() where i != index {
        state.packets[i].isSelected = false
      }
      if state.packets[index].isSelected {
        state.selectedPacket = index
      } else {
        state.selectedPacket = nil
      }
      state.forceUpdate.toggle()
      return .none
 
    case let .packet(index: index, action: .buttonTapped(.defaultBox)):
      state.packets[index].isDefault.toggle()
      for (i, packet) in state.packets.enumerated() where i != index {
        state.packets[i].isDefault = false
      }
      if state.packets[index].isDefault {
        state.defaultPacket = index
        return Effect(value: .defaultSelected(state.packets[index]))
      } else {
        state.defaultPacket = nil
        return Effect(value: .defaultSelected(nil))
      }

    case let .packet(index: index, action: action):
      state.forceUpdate.toggle()
      return .none
    
    case let .connectResultReceived(result):
      // TODO
      print("-----> PickerCore: NOT IMPLEMENTED \(action)")
      return .none
    }
  }
)
  .debug("PICKER ")

struct PacketsSubscriptionId: Hashable {}
struct ClientsSubscriptionId: Hashable {}

