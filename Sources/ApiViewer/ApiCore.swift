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
  case apiView
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
  public var showPicker = false
  public var pickerState: PickerState?
//  public var logState: LogState?
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
        print("RootCore: Log Viewer button tapped")
//        state.rootViewType = .log
//        state.logState = LogState(fontSize: state.fontSize)
      case .apiView:
        print("RootCore: Log Viewer button tapped")
//        state.rootViewType = .api
      case .startStop:
        state.pickerState = PickerState(pickType: .radio)
        state.showPicker = true
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
        print("RootCore: smartlink button tapped")
      case .status:
        print("RootCore: status button tapped")
      case .clearOnConnect:
        state.clearOnConnect.toggle()
      case .clearOnDisconnect:
        state.clearOnDisconnect.toggle()
      case .clearNow:
        print("RootCore: Clear Now button tapped")
      case .send:
        print("RootCore: Send button tapped")
      case .clearOnSend:
        state.clearOnSend.toggle()
      }
      return .none
      
    case .sheetClosed:
      print("RootCore: .sheetClosed")
      state.pickerState = nil
      return .none
      
    case let .fontSizeChanged(size):
      print("RootCore: .fontSizeChanged")
      state.fontSize = size
      return .none
      
    case let .commandToSendChanged(value):
      print("RootCore: .commandToSendChanged, \(value)")
      state.commandToSend = value
      return .none

    case let .pickerAction(.defaultSelected(packet)):
      print("RootCore: .pickerAction: \(action)")
      state.defaultPacket = packet
      return .none
      
    case .pickerAction(.buttonTapped(.cancel)):
      print("RootCore: .pickerAction: \(action)")
      state.showPicker = false
      state.pickerState = nil
      return .none
      
    case let .pickerAction(.connectResultReceived(index)):
      print("RootCore: .picker: \(action), index = \(index == nil ? "none" : String(index!))")
      return .none
      
    case .pickerAction(.buttonTapped(.test)):
      print("RootCore: .picker: \(action)")
      return .none
      
    case .pickerAction(_):
      print("RootCore: .pickerAction: \(action)")
      return .none
      
//    case .logAction(.buttonTapped(.apiView)):
//      print("RootCore: .logAction: \(action)")
//      state.logState = nil
//      state.viewType = .api
//      return .none
//
//    case let .logAction(.fontSizeChanged(size)):
//      print("RootCore: .logAction(.fontSizeChanged): \(size)")
//      state.fontSize = size
//      return .none
//
//    case .logAction(_):
//      print("RootCore: .logAction: \(action)")
//      return .none
    }
  }
)

//  .debug()
