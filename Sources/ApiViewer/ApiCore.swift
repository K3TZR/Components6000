//
//  ApiCore.swift
//  TestDiscoveryPackage/ApiViewer
//
//  Created by Douglas Adams on 11/24/21.
//

import ComposableArchitecture
import Dispatch

import Picker
import Discovery
import Shared

public enum ApiButton {
  case logView
  case startStop
  case gui
  case times
  case pings
  case replies
  case buttons
  case clearDefault
  case smartlink
  case status
  case clearNow
  case clearOnConnect
  case clearOnDisconnect
  case clearOnSend
  case send
}

public struct ApiState: Equatable {
  public var isGui = true
  public var showTimes = false
  public var showPings = false
  public var showReplies = false
  public var showButtons = false
  public var pickerState: PickerState? = nil
  public var connectedPacket: Packet? = nil
  public var defaultPacket: Packet? = nil
  public var clearNow = false
  public var clearOnConnect = false
  public var clearOnDisconnect = false
  public var clearOnSend = false
  public var fontSize: CGFloat = 12
  public var commandToSend = ""
  
  public init(fontSize: CGFloat) {
    self.fontSize = fontSize
  }
}

public enum ApiAction: Equatable {
  case buttonTapped(ApiButton)
  
  case sheetClosed
  case pickerAction(PickerAction)
  case fontSizeChanged(CGFloat)
  case commandToSendChanged(String)
}

public struct ApiEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
    listener: @escaping () -> Listener = { Listener() }
  )
  {
    self.queue = queue
    self.listener = listener
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
  var listener: () -> Listener
}

// swiftlint:disable trailing_closure
public let apiReducer = Reducer<ApiState, ApiAction, ApiEnvironment>.combine(
  pickerReducer
    .optional()
    .pullback(
      state: \ApiState.pickerState,
      action: /ApiAction.pickerAction,
      environment: { _ in PickerEnvironment() }
    ),
  Reducer { state, action, environment in
    switch action {
      
    case let .buttonTapped(button):
      switch button {
      case .logView:
        // handled by Root
        break
     case .startStop:
        state.pickerState = PickerState(pickType: .radio)
      case .gui:
        state.isGui.toggle()
      case .times:
        state.showTimes.toggle()
      case .pings:
        state.showPings.toggle()
      case .replies:
        state.showReplies.toggle()
      case .buttons:
        state.showButtons.toggle()
      case .clearDefault:
        state.defaultPacket = nil
      case .smartlink:
        print("-----> ApiCore: NOT IMPLEMENTED \(action)")
      case .status:
        print("-----> ApiCore: NOT IMPLEMENTED \(action)")
      case .clearOnConnect:
        state.clearOnConnect.toggle()
      case .clearOnDisconnect:
        state.clearOnDisconnect.toggle()
      case .clearNow:
        print("-----> ApiCore: NOT IMPLEMENTED \(action)")
      case .send:
        print("-----> ApiCore: NOT IMPLEMENTED \(action)")
      case .clearOnSend:
        state.clearOnSend.toggle()
      }
      return .none
      
    case .sheetClosed:
      state.pickerState = nil
      return .none
      
    case let .fontSizeChanged(size):
      state.fontSize = size
      return .none
      
    case let .commandToSendChanged(value):
      state.commandToSend = value
      return .none

    case let .pickerAction(.defaultSelected(packet)):
      state.defaultPacket = packet
      return .none
      
    case .pickerAction(.buttonTapped(.cancel)):
      state.pickerState = nil
      return .none
      
    case let .pickerAction(.connectResultReceived(index)):
      print("-----> ApiCore: NOT IMPLEMENTED \(action)")
      return .none
      
    case .pickerAction(.buttonTapped(.test)):
      print("-----> ApiCore: NOT IMPLEMENTED \(action)")
      return .none
      
    case .pickerAction(.buttonTapped(.connect)):
      print("-----> ApiCore: NOT IMPLEMENTED \(action)")
      return .none
      
    case .pickerAction(_):
      // IGNORE ALL OTHERS
      return .none
    }
  }
)
  .debug("API ")
