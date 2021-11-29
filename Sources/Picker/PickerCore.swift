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
  public init(listener: Listener,
              pickType: PickType = .radio,
              packets: [Packet] = [],
              selectedPacket: Int? = nil,
              defaultPacket: Int? = nil,
              connectedPacket: Int? = nil,
              forceUpdate: Bool = false,
              testStatus: Bool = false)
  {
    self.listener = listener
    self.pickType = pickType
    self.packets = packets
    self.selectedPacket = selectedPacket
    self.defaultPacket = defaultPacket
    self.connectedPacket = connectedPacket
    self.forceUpdate = forceUpdate
    self.testStatus = testStatus
  }
  
  public var listener: Listener
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
  case defaultSelected(Packet)
}

public struct PickerEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
    packetsEffect: @escaping (Listener) -> Effect<PickerAction, Never> = packetsSubscription(_:),
    clientsEffect: @escaping (Listener) -> Effect<PickerAction, Never> = clientsSubscription(_:)
  )
  {
    self.queue = queue
    self.packetsEffect = packetsEffect
    self.clientsEffect = clientsEffect
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
  var packetsEffect: (Listener) -> Effect<PickerAction, Never>
  var clientsEffect: (Listener) -> Effect<PickerAction, Never>
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
      return .concatenate( environment.packetsEffect(state.listener),
                           environment.clientsEffect(state.listener)
      )
      
    case let .buttonTapped(button):
      switch button {
      case .test:
        // TODO:
        //    return environment.testEffectStart(state.selectedPacket!)
        return .none
      
      case .cancel:
        return .cancel(ids: PacketsSubscriptionId(), ClientsSubscriptionId())
      
      case .connect:
        // TODO:
        //    return environment.connectEffectStart(state.selectedPacket!)
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
      // TODO:
      //    return environment.connectEffectStart(state.selectedPacket!)
      return .none

    case let .packet(index: index, action: .packetSelected):
      if state.packets[index].isSelected {
        state.selectedPacket = index
        for (i, packet) in state.packets.enumerated() where i != index {
          state.packets[i].isSelected = false
        }
      }
      state.forceUpdate.toggle()
      return .none
 
    case let .packet(index: index, action: .buttonTapped(.defaultBox)):
      state.defaultPacket = index
      state.forceUpdate.toggle()
      return Effect(value: .defaultSelected(state.packets[index]))

    case let .packet(index: index, action: action):
      state.forceUpdate.toggle()
      return .none
    
    case .connectResultReceived(_):
      return .none
    }
  }
)
  .debug()

struct PacketsSubscriptionId: Hashable {}
struct ClientsSubscriptionId: Hashable {}

