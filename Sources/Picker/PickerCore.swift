//
//  PickerCore.swift
//  Components6000/Picker
//
//  Created by Douglas Adams on 11/13/21.
//

import Combine
import ComposableArchitecture
import Dispatch
import AppKit

import Discovery
import Connection
import Shared

struct PacketEffectId: Hashable {}
struct ClientEffectId: Hashable {}
struct TestEffectId: Hashable {}
struct WanStatusSubscriptionId: Hashable {}

public struct PickerState: Equatable {
  public init(connectionType: ConnectionType = .gui,
              defaultSelection: PickerSelection? = nil,
              discovery: Discovery = Discovery.sharedInstance,
              pickerSelection: PickerSelection? = nil,
              testResult: SmartlinkTestResult? = nil)
  {
    self.connectionType = connectionType
    self.defaultSelection = defaultSelection
    self.discovery = discovery
    self.pickerSelection = pickerSelection
    self.testResult = testResult
  }
  
  public var connectionType: ConnectionType
  public var defaultSelection: PickerSelection?
  public var discovery: Discovery
  public var pickerSelection: PickerSelection?
  public var testResult: SmartlinkTestResult?
  public var forceUpdate = false
  public var alert: AlertState<PickerAction>?
  public var connectionState: ConnectionState?

}

public enum PickerAction: Equatable {
  case onAppear
  
  // UI controls
  case cancelButton
  case connectButton(PickerSelection)
  case defaultButton(PickerSelection)
  case testButton(PickerSelection)
  case selection(PickerSelection?)

  // sheet/alert related
  case alertCancelled
  case connectionAction(ConnectionAction)

  // effect related
  case clientChange(ClientChange)
  case checkConnections(PickerSelection)
  case packetChange(PacketChange)
  case testResultReceived(SmartlinkTestResult)
  case openSelection(PickerSelection)
  case wanStatus(WanStatus)
}

public struct PickerEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
    discoveryEffect: @escaping () -> Effect<PickerAction, Never> = liveDiscoveryEffect,
    testEffect: @escaping () -> Effect<PickerAction, Never> = liveTestEffect
  )
  {
    self.queue = queue
    self.discoveryEffect = discoveryEffect
    self.testEffect = testEffect
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
  var discoveryEffect: () -> Effect<PickerAction, Never>
  var testEffect: () -> Effect<PickerAction, Never>
}

public let pickerReducer = Reducer<PickerState, PickerAction, PickerEnvironment>.combine(
  connectionReducer
    .optional()
    .pullback(
      state: \PickerState.connectionState,
      action: /PickerAction.connectionAction,
      environment: { _ in ConnectionEnvironment() }
    ),
  Reducer { state, action, environment in
    switch action {
      // ----------------------------------------------------------------------------
      // MARK: - Picker UI actions

    case .cancelButton:
      // stop subscribing to Discovery broadcasts
      // handled downstream
      return .cancel(ids: PacketEffectId(), ClientEffectId())

    case .connectButton(let selection):
      if selection.packet.source == .smartlink {
          // get wan specific params (wanHandle)
          state.discovery.sendWanConnectMessage(for: selection.packet.serial, holePunchPort: selection.packet.negotiatedHolePunchPort)
          return .none
      } else {
        return Effect(value: .checkConnections(selection))
      }

    case .defaultButton(let selection):
      if state.defaultSelection == selection {
        state.defaultSelection = nil
      } else {
        state.defaultSelection = selection
      }
      // handled downstream
      return .none

    case .onAppear:
      // subscribe to Discovery broadcasts (long-running Effect)
      return .merge(environment.discoveryEffect(), wanStatus())
      
    case .selection(let selection):
      state.pickerSelection = selection
      if let selection = selection {
        if Shared.kVersionSupported < Version(selection.packet.version)  {
          // NO, return an Alert
          state.alert = .init(title: TextState(
                                """
                                Radio may be incompatible:
                                
                                Radio version is \(Version(selection.packet.version).string)
                                App supports <= \(kVersionSupported.string)
                                """
          )
          )
        }
      }
      return .none

    case .testButton(let selection):
      state.testResult = nil
      // try to send a Test
      if state.discovery.smartlinkTest(selection.packet.serial) {
        // SENT, wait for response
        return environment.testEffect()
      
      } else {
        // NOT SENT, alert
        NSSound.beep()
        return .none
      }
      
      // ----------------------------------------------------------------------------
      // MARK: - Connection actions
      
    case .connectionAction(.cancelButton):
      state.connectionState = nil
      return .none

    case .connectionAction(.connect(let selection, let disconnectHandle)):
      state.connectionState = nil
      // handled downstream (open radio)
      // stop subscribing to Discovery broadcasts
      return Effect(value: .openSelection(PickerSelection(selection.packet, selection.station, disconnectHandle)))

      // ----------------------------------------------------------------------------
      // MARK: - Alert actions
      
    case .alertCancelled:
      state.alert = nil
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Picker Effect actions

    case .clientChange(let update):
      // process a GuiClient change
      return .none
      
    case .checkConnections(let selection):
      // are there multiple Gui connections?
      if state.connectionType == .gui && selection.packet.guiClients.count > 0 {
        // YES, may need a disconnect, let the user choose
        state.connectionState = ConnectionState(pickerSelection: selection)
        return .none
      
      } else {
        // simple open
        return Effect(value: .openSelection(selection))
      }

    case .openSelection(_):
      // handled downstream
      return .cancel(ids: PacketEffectId(), ClientEffectId())
      
    case .packetChange(let update):
      // process a DiscoveryPacket change
      state.forceUpdate.toggle()
      return .none
      
    case .testResultReceived(let result):
      state.testResult = result
      return .cancel(ids: TestEffectId())
      
    case .connectionAction(_):
      return .none
      
    case.wanStatus(let status):
      if state.pickerSelection != nil && status.type == .connect && status.wanHandle != nil {
        state.pickerSelection!.packet.wanHandle = status.wanHandle!
        return .concatenate(
          .cancel(id: WanStatusSubscriptionId()),
          Effect(value: .openSelection(state.pickerSelection!)))
      }
      return .none
    }
  }
)
//  .debug("PICKER ")
