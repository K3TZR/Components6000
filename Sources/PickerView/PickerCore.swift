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
import WanDiscovery
import ClientView
import Shared

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums


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
  public var forceUpdate = false
  public var packetCollection: PacketCollection
  public var pickerSelection: PickerSelection?
  public var testResult: SmartlinkTestResult?
}

public enum PickerAction: Equatable {
  // UI controls
  case cancelButton
  case connectButton(PickerSelection)
  case defaultButton(PickerSelection)
  case selection(PickerSelection?)
  case testButton(PickerSelection)
  
  // sheet/alert related
  case alertCancelled
  
  // effect related
  case testResult(SmartlinkTestResult)
}

public struct PickerEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main }
    //    discoverySubscription: @escaping () -> Effect<PickerAction, Never> = { subscribeToDiscoveryPackets() }
  )
  {
    self.queue = queue
    //    self.discoverySubscription = discoverySubscription
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
  //  var discoverySubscription: () -> Effect<PickerAction, Never>
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

public let pickerReducer = Reducer<PickerState, PickerAction, PickerEnvironment>
{ state, action, environment in
  
  switch action {
    // ----------------------------------------------------------------------------
    // MARK: - UI actions
    
  case .cancelButton:
    // additional processing upstream
    return .none
    
  case .connectButton(let selection):
    return .none
    
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
                                
                                Radio is v\(Version(selection.packet.version).string)
                                App supports v\(kVersionSupported.string) or lower
                                """
        )
        )
      }
    }
    return .none
    
  case .testButton(let selection):
    state.testResult = nil
    // reply will generate a testResult action
    return subscribeToTest()
    
    // ----------------------------------------------------------------------------
    // MARK: - Alert actions
    
  case .alertCancelled:
    state.alert = nil
    return .none
    
    // ----------------------------------------------------------------------------
    // MARK: - Actions sent by publishers
    
  case .testResult(let result):
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
    return .cancel(ids: TestSubscriptionId())
  }
}
//  .debug("PICKER ")
