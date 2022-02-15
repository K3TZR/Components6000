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
import ClientStatus
import Shared

struct DiscoveryPacketSubscriptionId: Hashable {}
struct DiscoveryClientSubscriptionId: Hashable {}
struct TestResultSubscriptionId: Hashable {}
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
  
  public var alert: AlertState<PickerAction>?
  public var clientState: ClientState?
  public var connectionType: ConnectionType
  public var defaultSelection: PickerSelection?
  public var discovery: Discovery
  public var forceUpdate = false
  public var pickerSelection: PickerSelection?
  public var testResult: SmartlinkTestResult?
}

public enum PickerAction: Equatable {
  case onAppear
  
  // UI controls
  case cancelButton
  case connectButton(PickerSelection)
  case defaultButton(PickerSelection)
  case selection(PickerSelection?)
  case testButton(PickerSelection)

  // sheet/alert related
  case alertCancelled
  case clientAction(ClientAction)

  // effect related
  case checkConnections(PickerSelection)
  case clientChange(ClientChange)
  case openSelection(PickerSelection)
  case packetChange(PacketChange)
  case testResultReceived(SmartlinkTestResult)
  case wanStatus(WanStatus)
}

public struct PickerEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main }
  )
  {
    self.queue = queue
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
}

public let pickerReducer = Reducer<PickerState, PickerAction, PickerEnvironment>.combine(
  clientReducer
    .optional()
    .pullback(
      state: \PickerState.clientState,
      action: /PickerAction.clientAction,
      environment: { _ in ClientEnvironment() }
    ),
  Reducer { state, action, environment in
    switch action {
      // ----------------------------------------------------------------------------
      // MARK: - Initialization
      
    case .onAppear:
      // subscribe to Discovery & Wan effects
      return .merge(subscribeToDiscoveryPackets(), subscribeToWanStatus())
      
      // ----------------------------------------------------------------------------
      // MARK: - UI actions
      
    case .cancelButton:
      // stop subscriptions
      // handled upstream
      return .cancel(ids: DiscoveryPacketSubscriptionId(),
                     DiscoveryClientSubscriptionId(),
                     WanStatusSubscriptionId())

    case .connectButton(let selection):
      if selection.packet.source == .smartlink {
        // get wan specific params (wanHandle)
        state.discovery.sendWanConnectMessage(for: selection.packet.serial, holePunchPort: selection.packet.negotiatedHolePunchPort)
        // reply will generate a wanStatus action
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
      // handled upstream
      return .none

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
        // reply will generate a testResultReceived action
        return subscribeToTestResult()

      } else {
        // NOT SENT?
        NSSound.beep()
        return .none
      }
      
      // ----------------------------------------------------------------------------
      // MARK: - Client actions
      
    case .clientAction(.cancelButton):
      state.clientState = nil
      return .none

    case .clientAction(.connect(let selection, let disconnectHandle)):
      state.clientState = nil
      // tell upstream to open a connection
      return Effect(value: .openSelection(PickerSelection(selection.packet, selection.station, disconnectHandle)))

      // ----------------------------------------------------------------------------
      // MARK: - Alert actions
      
    case .alertCancelled:
      state.alert = nil
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Actions sent by publishers

    case .clientChange(let update):
      // process a GuiClient change
      return .none
      
    case .packetChange(let update):
      // process a DiscoveryPacket change
      state.forceUpdate.toggle()
      return .none
      
    case .testResultReceived(let result):
      state.testResult = result
      return .cancel(ids: TestResultSubscriptionId())
      
    case.wanStatus(let status):
      if state.pickerSelection != nil && status.type == .connect && status.wanHandle != nil {
        state.pickerSelection!.packet.wanHandle = status.wanHandle!
        // tell upstream to open a connection
        return Effect(value: .openSelection(state.pickerSelection!))
      }
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Actions sent by other actions

    case .checkConnections(let selection):
      // are there any Gui connections?
      if state.connectionType == .gui && selection.packet.guiClients.count > 0 {
        // YES, may need a disconnect, let the user choose
        state.clientState = ClientState(pickerSelection: selection)
        return .none
      
      } else {
        // tell upstream to open a connection
        return Effect(value: .openSelection(selection))
      }

    case .openSelection(_):
      // handled upstream
      // stop subscriptions
      return .cancel(ids: DiscoveryPacketSubscriptionId(),
                     DiscoveryClientSubscriptionId(),
                     WanStatusSubscriptionId(),
                     TestResultSubscriptionId())
    }
  }
)
//  .debug("PICKER ")
