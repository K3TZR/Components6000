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
import Shared

struct PacketEffectId: Hashable {}
struct ClientEffectId: Hashable {}
struct TestEffectId: Hashable {}

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
}

public enum PickerAction: Equatable {
  case onAppear
  
  // UI controls
  case cancelButton
  case connectButton(PickerSelection)
  case defaultButton(PickerSelection)
  case testButton(PickerSelection)
  case selection(PickerSelection?)

  // effect related
  case clientChange(ClientChange)
  case packetChange(PacketChange)
  case testResultReceived(SmartlinkTestResult)
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
  Reducer { state, action, environment in
    switch action {
      // ----------------------------------------------------------------------------
      // MARK: - Picker UI actions

    case .cancelButton:
      // stop subscribing to Discovery broadcasts
      return .cancel(ids: PacketEffectId(), ClientEffectId())

    case .connectButton(_):
      // handled downstream
      // stop subscribing to Discovery broadcasts
      return .cancel(ids: PacketEffectId(), ClientEffectId())

    case .defaultButton(let selection):
      if state.defaultSelection == selection {
        state.defaultSelection = nil
      } else {
        state.defaultSelection = selection
      }
      return .none

    case .onAppear:
      // subscribe to Discovery broadcasts (long-running Effect)
      return environment.discoveryEffect()
      
    case .selection(let selection):
      state.pickerSelection = selection
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
      // MARK: - Picker Effect actions

    case .clientChange(let update):
      // process a GuiClient change
      return .none
      
    case .packetChange(let update):
      // process a DiscoveryPacket change
      state.forceUpdate.toggle()
      return .none
      
    case .testResultReceived(let result):
      state.testResult = result
      return .cancel(ids: TestEffectId())
    }
  }
)
//  .debug("PICKER ")
