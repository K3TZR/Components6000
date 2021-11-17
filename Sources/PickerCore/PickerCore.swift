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
  case defaultButtonTapped(Packet)
  case testButtonTapped
  case testResultReceived(Bool)
  case cancelButtonTapped
  case connectButtonTapped
  case connectResultReceived(Bool)
  case packetsUpdate(PacketUpdate)
  case clientsUpdate(ClientUpdate)
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

public let pickerReducer = Reducer<PickerState, PickerAction, PickerEnvironment>
{ state, action, environment in
  switch action {

  case .onAppear:
    // start listening for Discovery broadcasts
    return .concatenate( environment.getPacketsEffect,
                         environment.getClientsEffect
    )

  case .defaultButtonTapped(let packet):
    // set/clear the Default property
    if state.defaultPacket == packet {
      state.defaultPacket = nil
    } else {
      state.defaultPacket = packet
    }
    return .none
    
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
  }
}

struct PacketPublisherId: Hashable {}
struct ClientPublisherId: Hashable {}
struct TestPublisherId: Hashable {}
struct ConnectPublisherId: Hashable {}

// ----------------------------------------------------------------------------
// MARK: - Production effects

private let listener = Listener()

public func packetsEffect() -> Effect<PickerAction, Never> {
  return listener.packetPublisher
    .receive(on: DispatchQueue.main)
    .map { update in .packetsUpdate(update) }
    .eraseToEffect()
    .cancellable(id: PacketPublisherId())
}

public func clientsEffect() -> Effect<PickerAction,Never> {
  return listener.clientPublisher
    .receive(on: DispatchQueue.main)
    .map { update in PickerAction.clientsUpdate(update) }
    .eraseToEffect()
    .cancellable(id: ClientPublisherId())
}

// TODO: Where is this publisher?
//public func testEffect(_ packet: Packet) -> Effect<PickerAction,Never> {
//  return listener.testPublisher
//    .receive(on: DispatchQueue.main)
//    .map { result in PickerAction.testResultReceived(result) }
//    .eraseToEffect()
//    .cancellable(id: TestPublisherId())
//}

// TODO: Where is this publisher?
//public func connectEffect(_ packet: Packet) -> Effect<PickerAction,Never> {
//  return listener.testPublisher
//    .receive(on: DispatchQueue.main)
//    .map { result in PickerAction.connectResultReceived(result) }
//    .eraseToEffect()
//    .cancellable(id: ConnectPublisherId())
//}

