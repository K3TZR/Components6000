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
              pickerSelection: PickerSelection? = nil,
              defaultSelection: PickerSelection? = nil,
              testResult: SmartlinkTestResult? = nil,
              discovery: Discovery = Discovery.sharedInstance)
  {
    self.defaultSelection = defaultSelection
    self.discovery = discovery
    self.connectionType = connectionType
    self.pickerSelection = pickerSelection
    self.testResult = testResult
  }
  
  public var defaultSelection: PickerSelection?
  public var discovery: Discovery
  public var connectionType: ConnectionType
  public var pickerSelection: PickerSelection?
  public var testResult: SmartlinkTestResult?
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
  case packetChange(PacketChange)
  case testResultReceived(SmartlinkTestResult)

  // 
  case selection(PickerSelection?)
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
      
    case .testButton(let selection):
      state.testResult = nil
      // try to send a Test
      if state.discovery.smartlinkTest(selection.packet.serial) {
        // SENT, wait for response
        return testEffect()
      
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

    case .selection(let selection):
      state.pickerSelection = selection
      return .none
    }
  }
)
//  .debug("PICKER ")
