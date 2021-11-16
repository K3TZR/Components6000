//
//  PickerCore.swift
//  TestDiscoveryPackage/PickerCore
//
//  Created by Douglas Adams on 11/13/21.
//

import ComposableArchitecture
import Dispatch
import Discovery

public struct PickerState: Equatable {
  public init(listener: Listener? = nil,
              packets: [Packet] = [],
              defaultPacket: Packet? = nil,
              forceUpdate: Bool = false,
              testStatus: Bool = false,
              selectedPacket: Packet? = nil,
              isConnected: Bool = false) {
    self.listener = listener
    self.packets = packets
    self.defaultPacket = defaultPacket
    self.forceUpdate = forceUpdate
    self.testStatus = testStatus
    self.selectedPacket = selectedPacket
    self.isConnected = false
  }
  
  public var listener: Listener?
  public var packets: [Packet] = []
  public var defaultPacket: Packet?
  public var forceUpdate = false
  public var testStatus = false
  public var selectedPacket: Packet?
  public var isConnected = false

}

public enum PickerAction: Equatable {
  case onAppear
  case listenerStarted(Listener)
  case onDisappear
  case defaultButtonTapped(Packet)
  case testButtonTapped
  case testResultReceived(Bool)
  case cancelButtonTapped
  case connectButtonTapped
  case connectResultReceived(Bool)
  case pickerUpdate(Listener.PacketUpdate)
  case guiClientUpdate(Listener.ClientUpdate)
}

public struct PickerEnvironment {
  public init(queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
              listenerEffectStart: @escaping () -> Effect<PickerAction, Never> = { listenerEffect() },
              packetEffectStart: @escaping (Listener) -> Effect<PickerAction, Never> = packetEffect(_:),
              guiClientEffectStart: @escaping (Listener) -> Effect<PickerAction, Never> = guiClientEffect(_:),
              testEffectStart: @escaping (Packet) -> Effect<PickerAction, Never> = testEffect(_:)) {

    self.queue = queue
    self.listenerEffectStart = listenerEffectStart
    self.packetEffectStart = packetEffectStart
    self.guiClientEffectStart = guiClientEffectStart
    self.testEffectStart = testEffectStart
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue> = { .main }
  var listenerEffectStart: () -> Effect<PickerAction, Never> = { listenerEffect() }
  var packetEffectStart: (Listener) -> Effect<PickerAction, Never> = packetEffect(_:)
  var guiClientEffectStart: (Listener) -> Effect<PickerAction, Never> = guiClientEffect(_:)
  var testEffectStart: (Packet) -> Effect<PickerAction, Never> = testEffect(_:)
  var connectEffectStart: (Packet) -> Effect<PickerAction, Never> = connectEffect(_:)
}

public let pickerReducer = Reducer<PickerState, PickerAction, PickerEnvironment>
{ state, action, environment in
  switch action {

  case .onAppear:
    // start listening for Discovery broadcasts
    return environment.listenerEffectStart()
    
  case .listenerStarted(let listener):
    state.listener = listener
    // initialize the Effects
    return .concatenate( environment.packetEffectStart(listener),
                         environment.guiClientEffectStart(listener)
    )

  case .defaultButtonTapped(let packet):
    // set/clear the Default property
    if state.defaultPacket == packet {
      state.defaultPacket = nil
    } else {
      state.defaultPacket = packet
    }
    return .none
    
  case .pickerUpdate(let update):
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

  case .guiClientUpdate(let update):
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

  case .onDisappear:
    // stop the Discovery effects.
    state.listener = nil
    return .cancel(ids: PacketPublisherId(), ClientPublisherId())
  
  case .testButtonTapped:
    // TODO:
    return environment.testEffectStart(state.selectedPacket!)

  case .testResultReceived(let result):
    // TODO: Bool versus actual test results???
    state.testStatus = result
    return .none

  case .cancelButtonTapped:
    // TODO:
    return .none

  case .connectButtonTapped:
    // TODO:
    return environment.connectEffectStart(state.selectedPacket!)

  case .connectResultReceived(let result):
    state.isConnected = result
    return .none
  }
}

struct PacketPublisherId: Hashable {}
struct ClientPublisherId: Hashable {}
struct TestPublisherId: Hashable {}
struct ConnectPublisherId: Hashable {}

// ----------------------------------------------------------------------------
// MARK: - Production effects

public func listenerEffect() -> Effect<PickerAction, Never> {
  return Effect(value: .listenerStarted( Listener() ))
}

public func packetEffect(_ listener: Listener) -> Effect<PickerAction, Never> {
  return listener.packetPublisher
    .receive(on: DispatchQueue.main)
    .map { update in .pickerUpdate(update) }
    .eraseToEffect()
    .cancellable(id: PacketPublisherId())
}

public func guiClientEffect(_ listener: Listener) -> Effect<PickerAction,Never> {
  return listener.clientPublisher
    .receive(on: DispatchQueue.main)
    .map { update in PickerAction.guiClientUpdate(update) }
    .eraseToEffect()
    .cancellable(id: ClientPublisherId())
}

// TODO: Where is this publisher?
public func testEffect(_ packet: Packet) -> Effect<PickerAction,Never> {
  return listener.testPublisher
    .receive(on: DispatchQueue.main)
    .map { result in PickerAction.testResultReceived(result) }
    .eraseToEffect()
    .cancellable(id: TestPublisherId())
}

// TODO: Where is this publisher?
public func connectEffect(_ packet: Packet) -> Effect<PickerAction,Never> {
  return listener.testPublisher
    .receive(on: DispatchQueue.main)
    .map { result in PickerAction.connectResultReceived(result) }
    .eraseToEffect()
    .cancellable(id: ConnectPublisherId())
}

