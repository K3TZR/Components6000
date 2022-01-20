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

public struct PickerSelection: Equatable {
  public init(_ source: PacketSource, _ serial: String, _ station: String?, _ guiClients: IdentifiedArrayOf<GuiClient>) {
    self.source = source
    self.serial = serial
    self.station = station
    self.guiClients = guiClients
  }

  public var source: PacketSource
  public var serial: String
  public var station: String?
  public var guiClients: IdentifiedArrayOf<GuiClient>
}

public struct PickerState: Equatable {
  public init(pickType: PickType = .radio,
              pickerSelection: PickerSelection? = nil,
              defaultSelection: PickerSelection? = nil,
              testStatus: Bool = false,
              discovery: Discovery = Discovery.sharedInstance)
  {
    self.defaultSelection = defaultSelection
    self.discovery = discovery
    self.pickType = pickType
    self.pickerSelection = pickerSelection
    self.testStatus = testStatus
  }
  
//  public var connectedPacket: Packet?
  public var defaultSelection: PickerSelection?
  public var discovery: Discovery
  public var pickType: PickType
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
      return .cancel(ids: PacketSubscriptionId(), ClientSubscriptionId())

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
      return environment.subscriptions()
      
    case .testButton(_):
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
      // MARK: - Packet actions

//    case let .packet(id: id, action: .defaultButton(selection)):
//      state.defaultSelection = selection
//      return .none

    case let .packet(id: id, action: .selection(selection)):
      state.pickerSelection = selection
      return .none
    }
  }
)
//  .debug("PICKER ")
