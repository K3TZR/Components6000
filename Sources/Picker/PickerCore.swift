//
//  PickerCore.swift
//  TestDiscoveryPackage/PickerCore
//
//  Created by Douglas Adams on 11/13/21.
//

import Combine
import ComposableArchitecture
import Dispatch
import Discovery


public enum PacketAction {
  case checkboxTapped
}

public struct PacketEnvironment {
}

let packetReducer = Reducer<Packet, PacketAction, PacketEnvironment> {
  state, action, environment in
  switch action {
  case .checkboxTapped:
    state.isDefault.toggle()
    return .none
  }
}

public struct PickerState: Equatable {
  public init( packets: [Packet] = [],
              defaultPacket: Packet? = nil,
              forceUpdate: Bool = false,
              testStatus: Bool = false,
              selectedPacket: Packet? = nil,
              isConnected: Bool = false) {
    self.packets = packets
    self.defaultPacket = defaultPacket
    self.forceUpdate = forceUpdate
    self.testStatus = testStatus
    self.selectedPacket = selectedPacket
    self.isConnected = false
  }
  
  public var packets: [Packet] = []
  public var defaultPacket: Packet?
  public var forceUpdate = false
  public var testStatus = false
  public var selectedPacket: Packet?
  public var isConnected = false
}

public enum PickerAction: Equatable {
  case onAppear
  case onDisappear
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
  public init(queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
              getPacketsEffect: Effect<PickerAction, Never> = packetsEffect(),
              getClientsEffect: Effect<PickerAction, Never> = clientsEffect()
//              doTestEffect: @escaping (Packet) -> Effect<PickerAction, Never> = testEffect(_:)
//              doConnectEffect: @escaping (Packet) -> Effect<PickerAction, Never> = connectEffect(_:)
  ) {

    self.queue = queue
    self.getPacketsEffect = getPacketsEffect
    self.getPacketsEffect = getPacketsEffect
//    self.doTestEffect = doTestEffect
//    self.doConnectEffect = doConnectEffect
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue> = { .main }
  var getPacketsEffect: Effect<PickerAction, Never> = packetsEffect()
  var getClientsEffect: Effect<PickerAction, Never> = clientsEffect()
//  var doTestEffect: (Packet) -> Effect<PickerAction, Never> = testEffect(_:)
//  var doConnectEffect: (Packet) -> Effect<PickerAction, Never> = connectEffect(_:)
}

public let pickerReducer = Reducer<PickerState, PickerAction, PickerEnvironment>.combine(
  packetReducer.forEach(state: \.packets,
                        action: /PickerAction.packet(index:action:),
                        environment: { _ in PacketEnvironment() }
                       ),
  Reducer { state, action, environment in
    switch action {
      
    case .onAppear:
      // start listening for Discovery broadcasts
      return .concatenate( environment.getPacketsEffect,
                           environment.getClientsEffect
      )
      
    case .packetsUpdate(let update):
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
      
    case .clientsUpdate(let update):
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
      
    case .testResultReceived(let result):
      // TODO: Bool versus actual test results???
      state.testStatus = result
      return .none
      
    case .cancelButtonTapped:
      // TODO:
      return .none
      
    case .connectButtonTapped:
      // TODO:
      //    return environment.connectEffectStart(state.selectedPacket!)
      return .none
      
    case .connectResultReceived(let result):
      state.isConnected = result
      return .none
      
    case .onDisappear:
      // stop the Discovery effects.
      return .cancel(ids: PacketPublisherId(), ClientPublisherId())

    case .packet(index: let index, action: let action):
      state.forceUpdate.toggle()
      return .none
    }
  }
)
  .debug()

struct PacketPublisherId: Hashable {}
struct ClientPublisherId: Hashable {}
struct TestPublisherId: Hashable {}
struct ConnectPublisherId: Hashable {}

