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
  public var listener: Listener?
  public var packets: [Packet] = []
  public var defaultPacket: Packet?
  public var forceUpdate = false

  public init() {}
}

public enum PickerAction: Equatable {
  case onAppear
  case listenerStarted(Listener)
  case onDisappear
  case defaultButtonTapped(Packet)
  case pickerUpdate(Listener.PacketUpdate)
  case guiClientUpdate(Listener.ClientUpdate)
}

public struct PickerEnvironment {
  public init(queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main }, listenerEffectStart: @escaping () -> Effect<PickerAction, Never> = { listenerEffect() }, packetEffectStart: @escaping (Listener) -> Effect<PickerAction, Never> = packetEffect(_:), guiClientEffectStart: @escaping (Listener) -> Effect<PickerAction, Never> = guiClientEffect(_:)) {

    self.queue = queue
    self.listenerEffectStart = listenerEffectStart
    self.packetEffectStart = packetEffectStart
    self.guiClientEffectStart = guiClientEffectStart
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue> = { .main }
  var listenerEffectStart: () -> Effect<PickerAction, Never> = { listenerEffect() }
  var packetEffectStart: (Listener) -> Effect<PickerAction, Never> = packetEffect(_:)
  var guiClientEffectStart: (Listener) -> Effect<PickerAction, Never> = guiClientEffect(_:)

  
  
//  public static let live = Self(
//    queue: { .main },
//    listenerEffectStart: { listenerEffect() },
//    packetEffectStart: packetEffect(_:),
//    guiClientEffectStart: guiClientEffect(_:)
//  )
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
      print("Discovery: packet added, \(update.packet.nickname), \(update.packet.guiClientStations)")
      state.packets = update.packets
      state.forceUpdate.toggle()
    case .updated:
      print("Discovery: packet updated, \(update.packet.nickname), \(update.packet.guiClientStations)")
      state.packets = update.packets
      state.forceUpdate.toggle()
    case .deleted:
      print("Discovery: packet deleted, \(update.packet.nickname), \(update.packet.guiClientStations)")
      state.packets = update.packets
      state.forceUpdate.toggle()
    }
    return .none

  case .guiClientUpdate(let update):
    // process a GuiClient change
    switch update.action {
    case .add:
      print("Discovery: GuiClient added, \(update.client.clientHandle), \(update.client.station)")
      state.forceUpdate.toggle()
    case .update:
      print("Discovery: GuiClient updated, \(update.client.clientHandle), \(update.client.station)")
      state.forceUpdate.toggle()
    case .delete:
      print("Discovery: GuiClient deleted, \(update.client.clientHandle), \(update.client.station)")
      state.forceUpdate.toggle()
    }
    return .none

  case .onDisappear:
    // stop the Discovery effect.
    state.listener = nil
    return .cancel(ids: PacketPublisherId(), ClientPublisherId())
  }
}

struct PacketPublisherId: Hashable {}
struct ClientPublisherId: Hashable {}

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
