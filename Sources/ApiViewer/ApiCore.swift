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
  case isGui
  case showTimes
  case showPings
  case showReplies
  case showButtons
  case clearDefault
  case smartlinkLogin
  case status
  case clearNow
  case clearOnConnect
  case clearOnDisconnect
  case clearOnSend
  case send
}

public struct ApiState: Equatable {
  public let kAppName = "TestDiscoveryApp"
  public let kPlatform = "macOS"

  public var clearNow = false
  public var clearOnConnect = false
  public var clearOnDisconnect = false
  public var clearOnSend = false
  public var commandToSend = ""
  public var connectedPacket: Packet? = nil
  public var defaultPacket: UUID? = nil
  public var discovery: Discovery? = nil
  public var discoveryAlert: DiscoveryAlert?
  public var fontSize: CGFloat = 12
  public var isGui = true
  public var pickerState: PickerState? = nil
  public var showButtons = false
  public var showTimes = false
  public var showPings = false
  public var showReplies = false
  public var smartlinkEmail: String

  
  public init(fontSize: CGFloat, smartlinkEmail: String) {
    self.smartlinkEmail = smartlinkEmail
    self.fontSize = fontSize
  }
}

public enum ApiAction: Equatable {
  case onAppear
  case buttonTapped(ApiButton)
  
  case sheetClosed
  case pickerAction(PickerAction)
  case fontSizeChanged(CGFloat)
  case commandToSendChanged(String)
  case discoveryAlertDismissed
}

public struct ApiEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main }
  )
  {
    self.queue = queue
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
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
        if state.pickerState == nil {
          state.pickerState = PickerState(pickType: .radio)
        } else {
          state.pickerState = nil
        }
      case .isGui:
        state.isGui.toggle()
      case .showTimes:
        state.showTimes.toggle()
      case .showPings:
        state.showPings.toggle()
      case .showReplies:
        state.showReplies.toggle()
      case .showButtons:
        state.showButtons.toggle()
      case .clearDefault:
        state.defaultPacket = nil
      case .smartlinkLogin:
        print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      case .status:
        print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      case .clearOnConnect:
        state.clearOnConnect.toggle()
      case .clearOnDisconnect:
        state.clearOnDisconnect.toggle()
      case .clearNow:
        print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      case .send:
        print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      case .clearOnSend:
        state.clearOnSend.toggle()
      }
      return .none
      
    case .onAppear:
      state.discovery = Discovery.sharedInstance
      do {
        try state.discovery?.startListeners(smartlinkEmail: state.smartlinkEmail,
                                            appName: state.kAppName,
                                            platform: state.kPlatform)
      } catch {
        state.discoveryAlert = DiscoveryAlert(title: "Failed to load Discovery")
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

    case let .pickerAction(.defaultSelected(id)):
      print("---------- ApiCore: .defaultSelected, id = \(id)")
      state.defaultPacket = id
      return .none
      
    case .pickerAction(.buttonTapped(.cancel)):
      state.pickerState = nil
      return .none
      
    case let .pickerAction(.connectResultReceived(index)):
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none
      
    case .pickerAction(.buttonTapped(.test)):
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none
      
    case .pickerAction(.buttonTapped(.connect)):
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none
      
    case .pickerAction(_):
      // IGNORE ALL OTHERS
      return .none

    case .discoveryAlertDismissed:
      state.discoveryAlert = nil
      return .none
    }
  }
)
  .debug("API ")
