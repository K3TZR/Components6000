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

import LanDiscovery
import Login
import ClientStatus
import Shared

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

struct DiscoveryPacketSubscriptionId: Hashable {}
struct DiscoveryClientSubscriptionId: Hashable {}
struct TestResultSubscriptionId: Hashable {}
struct WanStatusSubscriptionId: Hashable {}

// ----------------------------------------------------------------------------
// MARK: - State, Actions & Environment

public struct PickerState: Equatable {
  public init(connectionType: ConnectionType = .gui,
              defaultSelection: PickerSelection? = nil,
              packetCollection: PacketCollection = PacketCollection.sharedInstance,
              pickerSelection: PickerSelection? = nil,
              testResult: SmartlinkTestResult? = nil)
  {
    self.connectionType = connectionType
    self.defaultSelection = defaultSelection
    self.packetCollection = packetCollection
    self.pickerSelection = pickerSelection
    self.testResult = testResult
  }
  
  public var alert: AlertState<PickerAction>?
  public var clientState: ClientState?
  public var connectionType: ConnectionType
  public var defaultSelection: PickerSelection?
  public var packetCollection: PacketCollection
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
  case checkConnectionStatus(PickerSelection)
  case clientChangeReceived(ClientUpdate)
  case openSelection(PickerSelection)
  case packetChangeReceived(PacketUpdate)
  case testResultReceived(SmartlinkTestResult)
  case wanStatusReceived(WanStatus)
}

public struct PickerEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
    discoverySubscription: @escaping () -> Effect<PickerAction, Never> = { subscribeToDiscoveryPackets() }
  )
  {
    self.queue = queue
    self.discoverySubscription = discoverySubscription
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
  var discoverySubscription: () -> Effect<PickerAction, Never>
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

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
      return .merge(environment.discoverySubscription(), subscribeToWanStatus())
      
      // ----------------------------------------------------------------------------
      // MARK: - UI actions
      
    case .cancelButton:
      // stop subscriptions
      // additional processing upstream
      return .cancel(ids: DiscoveryPacketSubscriptionId(),
                     DiscoveryClientSubscriptionId(),
                     WanStatusSubscriptionId())

    case .connectButton(let selection):
      if selection.packet.source == .smartlink {
        // get wan specific params (wanHandle)
//        state.discovery.sendWanConnectMessage(for: selection.packet.serial, holePunchPort: selection.packet.negotiatedHolePunchPort)
        // reply will generate a wanStatusReceived action
        return .none
      } else {
        // check for other connections
        return Effect(value: .checkConnectionStatus(selection))
      }

    case .defaultButton(let selection):
      if state.defaultSelection == selection {
        state.defaultSelection = nil
      } else {
        state.defaultSelection = selection
      }
      // additional processing upstream
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
//      state.testResult = nil
//      // try to send a Test
//      if state.discovery.sendSmartlinkTest(selection.packet.serial) {
//        // reply will generate a testResultReceived action
//        return subscribeToTestResult()
//
//      } else {
//        // NOT SENT (why?)
//        NSSound.beep()
//        return .none
//      }
      
      
      // FIXME: !!!!!!
      
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Client actions
      
    case .clientAction(.cancelButton):
      state.clientState = nil
      // additional processing upstream
      return .none

    case .clientAction(.connect(let selection, let disconnectHandle)):
      state.clientState = nil
      return Effect(value: .openSelection(PickerSelection(selection.packet, selection.station, disconnectHandle)))

      // ----------------------------------------------------------------------------
      // MARK: - Alert actions
      
    case .alertCancelled:
      state.alert = nil
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Actions sent by publishers

    case .clientChangeReceived(let update):
      // process a GuiClient change
      // additional processing upstream
      return .none
      
    case .packetChangeReceived(let update):
      // process a DiscoveryPacket change
      state.forceUpdate.toggle()
      // additional processing upstream
      return .none
      
    case .testResultReceived(let result):
      state.testResult = result
      if !result.success {
        state.alert = .init(
          title: TextState(
                    """
                    Smartlink test FAILED:
                    """
          )
        )
      }
      return .cancel(ids: TestResultSubscriptionId())
      
    case .wanStatusReceived(let status):
      if state.pickerSelection != nil && status.type == .connect && status.wanHandle != nil {
        state.pickerSelection!.packet.wanHandle = status.wanHandle!
        // check for other connections
        return Effect(value: .checkConnectionStatus(state.pickerSelection!))
      }
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Actions sent by other actions

    case .checkConnectionStatus(let selection):
      // are there any Gui connections?
      if state.connectionType == .gui && selection.packet.guiClients.count > 0 {
        // YES, may need a disconnect, let the user choose
        state.clientState = ClientState(pickerSelection: selection)
        return .none

      } else {
        // NO, proceed to opening
        return Effect(value: .openSelection(selection))
      }
      
    case .openSelection(_):
      // stop subscriptions
      // additional processing upstream
      return .cancel(ids: DiscoveryPacketSubscriptionId(),
                     DiscoveryClientSubscriptionId(),
                     WanStatusSubscriptionId(),
                     TestResultSubscriptionId())
    }
  }
)
//  .debug("PICKER ")

// ----------------------------------------------------------------------------
// MARK: - Helper methods

public func subscribeToDiscoveryPackets() -> Effect<PickerAction, Never> {
  Effect.merge(
    PacketCollection.sharedInstance.packetPublisher
      .receive(on: DispatchQueue.main)
      .map { update in .packetChangeReceived(update) }
      .eraseToEffect()
      .cancellable(id: DiscoveryPacketSubscriptionId()),
    
    PacketCollection.sharedInstance.clientPublisher
      .receive(on: DispatchQueue.main)
      .map { update in .clientChangeReceived(update) }
      .eraseToEffect()
      .cancellable(id: DiscoveryClientSubscriptionId())
  )
}

public func subscribeToTestResult() -> Effect<PickerAction, Never> {
  Effect(
    Authentication.sharedInstance.testPublisher
      .receive(on: DispatchQueue.main)
      .map { result in .testResultReceived(result) }
      .eraseToEffect()
      .cancellable(id: TestResultSubscriptionId())
  )
}

public func subscribeToWanStatus() -> Effect<PickerAction, Never> {
  Effect(
    Authentication.sharedInstance.wanStatusPublisher
      .receive(on: DispatchQueue.main)
      .map { status in .wanStatusReceived(status) }
      .eraseToEffect()
      .cancellable(id: WanStatusSubscriptionId())
  )
}
