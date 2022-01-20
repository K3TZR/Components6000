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

struct PacketEffectId: Hashable {}
struct ClientEffectId: Hashable {}

public enum PickerButton: Equatable {
  case test
  case cancel
  case connect
}

public struct PickerSelection: Equatable {
  public init(_ packet: Packet, _ station: String?) {
    self.packet = packet
    self.station = station
  }

  public var packet: Packet
  public var station: String?
}

public struct PickerState: Equatable {
  public init(connectionType: ConnectionType = .gui,
              pickerSelection: PickerSelection? = nil,
              defaultSelection: PickerSelection? = nil,
              testStatus: Bool = false,
              discovery: Discovery = Discovery.sharedInstance)
  {
    self.defaultSelection = defaultSelection
    self.discovery = discovery
    self.connectionType = connectionType
    self.pickerSelection = pickerSelection
    self.testStatus = testStatus
  }
  
//  public var connectedPacket: Packet?
  public var defaultSelection: PickerSelection?
  public var discovery: Discovery
  public var connectionType: ConnectionType
  public var pickerSelection: PickerSelection?
  public var testStatus = false
  public var forceUpdate = false
}

public enum PickerAction: Equatable {
  case onAppear
  
  // UI controls
  case cancelButton
  case connectButton(PickerSelection)
  case testButton(PickerSelection)
  case defaultButton(PickerSelection)

  // effect related
  case clientChange(ClientChange)
  case connectResultReceived(Int?)
  case packetChange(PacketChange)
  case testResultReceived(Bool)

  // upstream actions
  case packet(id: UUID, action: PacketAction)
}

public struct PickerEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
    discoveryEffect: @escaping () -> Effect<PickerAction, Never> = liveDiscoveryEffect
  )
  {
    self.queue = queue
    self.discoveryEffect = discoveryEffect
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
  var discoveryEffect: () -> Effect<PickerAction, Never>
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
      // MARK: - Packet actions

    case let .packet(id: id, action: .selection(selection)):
      state.pickerSelection = selection
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Picker UI actions

    case .cancelButton:
      // FIXME: probably should not do this here
      // stop listening for Discovery broadcasts (long-running Effect)
      return .cancel(ids: PacketEffectId(), ClientEffectId())

    case .connectButton(_):
      // handled downstream
      return .cancel(ids: PacketEffectId(), ClientEffectId())

    case .defaultButton(let selection):
      if state.defaultSelection == selection {
        state.defaultSelection = nil
      } else {
        state.defaultSelection = selection
      }
      return .none

    case .onAppear:
      // FIXME: probably should not do this here
      // start listening for Discovery broadcasts (long-running Effect)
      return environment.discoveryEffect()
      
    case .testButton(_):
      // handled downstream
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Picker Effect actions

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
    }
  }
)
//  .debug("PICKER ")
