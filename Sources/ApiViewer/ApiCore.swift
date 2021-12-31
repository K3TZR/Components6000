//
//  ApiCore.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 11/24/21.
//

import ComposableArchitecture
import Dispatch

import Login
import Picker
import Discovery
import LogProxy
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
  public var loginState: LoginState? = nil
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
  case buttonTapped(ApiButton)
  case commandToSendChanged(String)
  case discoveryAlertDismissed
  case fontSizeChanged(CGFloat)
  case loginAction(LoginAction)
  case loginClosed
  case onAppear
  case pickerAction(PickerAction)
  case sheetClosed
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
          state.pickerState = PickerState(pickType: state.isGui ? .radio : .station)
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
        try state.discovery?.startLanListener()
      } catch LanListenerError.kSocketError {
        state.discoveryAlert = DiscoveryAlert(title: "Discovery: Lan Listener, Failed to open a socket")
      } catch LanListenerError.kReceivingError {
        state.discoveryAlert = DiscoveryAlert(title: "Discovery: Lan Listener, Failed to start receiving")
      } catch {
        state.discoveryAlert = DiscoveryAlert(title: "Discovery: Lan Listener, unknown error")
      }

      do {
        try state.discovery?.startWanListener(smartlinkEmail: "douglas.adams@me.com")
      } catch WanListenerError.kFailedToObtainIdToken {
        state.discoveryAlert = DiscoveryAlert(title: "Discovery: Wan Listener, Failed to Obtain IdToken")
        
          state.loginState = LoginState()

      } catch WanListenerError.kFailedToConnect {
        state.discoveryAlert = DiscoveryAlert(title: "Discovery: Wan Listener, Failed to Connect")
      } catch {
        state.discoveryAlert = DiscoveryAlert(title: "Discovery: Wan Listener, unknown error")
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
      state.defaultPacket = id
      return .none
      
    case .pickerAction(.cancelButton):
      state.pickerState = nil
      return .none
      
    case let .pickerAction(.connectResultReceived(index)):
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none
      
    case .pickerAction(.testButton):
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none
      
    case .pickerAction(.connectButton):
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none
      
    case .pickerAction(_):
      // IGNORE ALL OTHERS
      return .none

    case .discoveryAlertDismissed:
      state.discoveryAlert = nil
      return .none
    
    case .loginAction(.cancelButton):
      print("-----> Login: Cancel button")
      state.loginState = nil
      return .none

    case let .loginAction(.loginButton(result)):
      print("-----> Login: Login button, User = \(result.email), Pwd = \(result.pwd)")
      state.loginState = nil
      return .none
    
    case .loginClosed:
      state.loginState = nil

      do {
        try state.discovery?.startWanListener(smartlinkEmail: "douglas.adams@me.com")
      } catch WanListenerError.kFailedToObtainIdToken {
        state.discoveryAlert = DiscoveryAlert(title: "Discovery: Wan Listener, Failed to Obtain IdToken")
        
      } catch WanListenerError.kFailedToConnect {
        state.discoveryAlert = DiscoveryAlert(title: "Discovery: Wan Listener, Failed to Connect")
      } catch {
        state.discoveryAlert = DiscoveryAlert(title: "Discovery: Wan Listener, unknown error")
      }
      return .none
    }
  }
)
//  .debug("API ")
