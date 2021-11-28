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

public struct PickerState: Equatable {
  public init(listener: Listener,
              packets: [Packet] = [],
              defaultPacket: Int? = nil,
              forceUpdate: Bool = false,
              testStatus: Bool = false,
              isConnected: Bool = false,
              pickType: PickType = .radio,
              pickerShouldClose: Bool = false,
              selectedPacket: Int? = nil)
  {
    self.listener = listener
    self.packets = packets
    self.defaultPacket = defaultPacket
    self.forceUpdate = forceUpdate
    self.testStatus = testStatus
    self.isConnected = false
    self.pickType = pickType
    self.selectedPacket = selectedPacket
  }
  
  public var listener: Listener
  public var packets: [Packet] = []
  public var defaultPacket: Int? = nil
  public var forceUpdate = false
  public var testStatus = false
  public var isConnected = false
  public var pickType: PickType = .radio
  public var selectedPacket: Int? = nil
}

public enum PickerAction: Equatable {
  case onAppear
  case testButtonTapped
  case testResultReceived(Bool)
  case cancelButtonTapped
  case connectButtonTapped
  case connectResultReceived(Bool)
  case packetsUpdate(PacketUpdate)
  case clientsUpdate(ClientUpdate)
  case packet(index: Int, action: PacketAction)
}

public struct PickerEnvironment {
  public init(queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main }
  )
  {
    self.queue = queue
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue> = { .main }
  var packetsEffect: (Listener) -> Effect<PickerAction, Never> = packetsSubscription(_:)
  var clientsEffect: (Listener) -> Effect<PickerAction, Never> = clientsSubscription(_:)
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
      
    case let .packetsUpdate(update):
      // process a DiscoveryPacket change
      switch update.action {
      case .added:
        state.packets = update.packets
        state.forceUpdate.toggle()
        
      case .updated:
        state.packets = update.packets
        state.forceUpdate.toggle()
        
      case .deleted:
        state.packets = update.packets
        state.forceUpdate.toggle()
      }
      return .none
      
    case let .clientsUpdate(update):
      // process a GuiClient change
      switch update.action {
        
      case .add:
        state.forceUpdate.toggle()
      case .update:
        state.forceUpdate.toggle()
      case .delete:
        state.forceUpdate.toggle()
      }
      return .none
      
    case .testButtonTapped:
      // TODO:
      //    return environment.testEffectStart(state.selectedPacket!)
      return .none
      
    case let .testResultReceived(result):
      // TODO: Bool versus actual test results???
      state.testStatus = result
      return .none
      
    case .cancelButtonTapped:
      // TODO:
      print("PickerCore: .cancelButtonTapped")
      return .cancel(ids: PacketsSubscriptionId(), ClientsSubscriptionId())

    case .connectButtonTapped:
      // TODO:
      //    return environment.connectEffectStart(state.selectedPacket!)
      return .none
      
    case let .connectResultReceived(result):
      state.isConnected = result
      return .none
      
    case let .packet(index: index, action: .packetSelected):
      print("PickerCore: .packet, index=\(index), action=\(action)")
      if state.packets[index].isSelected {
        state.selectedPacket = index
        for (i, packet) in state.packets.enumerated() where i != index {
          state.packets[i].isSelected = false
        }
      }
      state.forceUpdate.toggle()
      return .none
 
    case let .packet(index: index, action: .defaultButtonClicked):
      print("PickerCore: .defaultButtonClicked, index=\(index), action=\(action)")
      if state.packets[index].isDefault {
        state.defaultPacket = index
        for (i, packet) in state.packets.enumerated() where i != index {
          state.packets[i].isDefault = false
        }
      }
      state.forceUpdate.toggle()
      return .none

    case let .packet(index: index, action: action):
      print("PickerCore: .packet, index=\(index), action=\(action)")
      state.forceUpdate.toggle()
      return .none
    }
  }
)
//  .debug()

struct PacketsSubscriptionId: Hashable {}
struct ClientsSubscriptionId: Hashable {}

