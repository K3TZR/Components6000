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
import Shared

public enum ConnectionMode: String {
  case local
  case smartlink
  case both
}

public struct ApiState: Equatable {
  // State held in User Defaults
  public var clearOnConnect: Bool { didSet { UserDefaults.standard.set(clearOnConnect, forKey: "clearOnConnect")} }
  public var clearOnDisconnect: Bool { didSet { UserDefaults.standard.set(clearOnDisconnect, forKey: "clearOnDisconnect")} }
  public var clearOnSend: Bool { didSet { UserDefaults.standard.set(clearOnSend, forKey: "clearOnSend")} }
  public var connectionMode: ConnectionMode { didSet { UserDefaults.standard.set(connectionMode.rawValue, forKey: "connectionMode")} }
  public var fontSize: CGFloat { didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize")} }
  public var isGui: Bool { didSet { UserDefaults.standard.set(isGui, forKey: "isGui")} }
  public var wanLogin: Bool { didSet { UserDefaults.standard.set(wanLogin, forKey: "wanLogin")} }
  public var showTimes: Bool { didSet { UserDefaults.standard.set(showTimes, forKey: "showTimes")} }
  public var showPings: Bool { didSet { UserDefaults.standard.set(showPings, forKey: "showPings")} }
  public var showReplies: Bool { didSet { UserDefaults.standard.set(showReplies, forKey: "showReplies")} }
  public var smartlinkEmail: String { didSet { UserDefaults.standard.set(smartlinkEmail, forKey: "smartlinkEmail")} }

  // normal state
  public var clearNow = false
  public var commandToSend = ""
  public var connectedPacket: Packet? = nil
  public var defaultPacket: UUID? = nil
  public var discovery: Discovery? = nil
  public var alert: AlertView?
  public var loginState: LoginState? = nil
  public var pickerState: PickerState? = nil
    
  public init() {
    clearOnConnect = UserDefaults.standard.bool(forKey: "clearOnConnect")
    clearOnDisconnect = UserDefaults.standard.bool(forKey: "clearOnDisconnect")
    clearOnSend = UserDefaults.standard.bool(forKey: "clearOnSend")
    connectionMode = ConnectionMode(rawValue: UserDefaults.standard.string(forKey: "connectionMode") ?? "both") ?? .both
    fontSize = UserDefaults.standard.double(forKey: "fontSize") == 0 ? 12 : UserDefaults.standard.double(forKey: "fontSize")
    isGui = UserDefaults.standard.bool(forKey: "isGui")
    wanLogin = UserDefaults.standard.bool(forKey: "wanLogin")
    showTimes = UserDefaults.standard.bool(forKey: "showTimes")
    showPings = UserDefaults.standard.bool(forKey: "showPings")
    showReplies = UserDefaults.standard.bool(forKey: "showReplies")
    smartlinkEmail = UserDefaults.standard.string(forKey: "smartlinkEmail") ?? ""
  }
}

public enum ApiAction: Equatable {
  case alertDismissed
  case loginAction(LoginAction)
  case loginClosed
  case onAppear
  case pickerAction(PickerAction)
  case sheetClosed

  // UI controls
  case clearDefaultButton
  case clearNowButton
  case clearOnConnectButton
  case clearOnDisconnectButton
  case clearOnSendButton
  case commandTextfield(String)
  case fontSizeStepper(CGFloat)
  case isGuiButton
  case logViewButton
  case modePicker(ConnectionMode)
  case sendButton
  case showPingsButton
  case showRepliesButton
  case showTimesButton
  case startStopButton
  case wanLoginButton

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
      
      // ----------------------------------------------------------------------------
      // MARK: - UI actions

    case .clearDefaultButton:
      state.defaultPacket = nil
      return .none

    case .clearNowButton:
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none

    case .clearOnConnectButton:
      state.clearOnConnect.toggle()
      return .none

    case .clearOnDisconnectButton:
      state.clearOnDisconnect.toggle()
      return .none

    case .clearOnSendButton:
      state.clearOnSend.toggle()
      return .none
      
    case let .commandTextfield(value):
      state.commandToSend = value
      return .none
      
    case let .fontSizeStepper(size):
      state.fontSize = size
      return .none
      
    case .isGuiButton:
      state.isGui.toggle()
      return .none

    case .logViewButton:
      // handled by Root
      return .none
    
    case let .modePicker(mode):
      state.connectionMode = mode
      return .none

    case .onAppear:
      startListening(&state)
      return .none
      
    case .sendButton:
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none

    case .sheetClosed:
      state.pickerState = nil
      return .none
      
    case .showPingsButton:
      state.showPings.toggle()
      return .none

    case .showRepliesButton:
      state.showReplies.toggle()
      return .none

    case .showTimesButton:
      state.showTimes.toggle()
      return .none

    case .startStopButton:
      if state.pickerState == nil {
        state.pickerState = PickerState(pickType: state.isGui ? .radio : .station)
      } else {
        state.pickerState = nil
      }
      return .none
    
    case .wanLoginButton:
      state.wanLogin.toggle()
      state.alert = AlertView(title: "Takes effect when App restarted")
      return .none
      
//    case let .pickerAction(.defaultSelected(id)):
//      state.defaultPacket = id
//      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Upstream actions (Picker)

    case .pickerAction(.cancelButton):
      state.pickerState = nil
      return .none
      
    case let .pickerAction(.connectButton(packet)):
      print("-----> ApiCore: Connect, packet = \(packet!.nickname)")
      return .none
      
    case let .pickerAction(.connectResultReceived(index)):
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none
      
    case let .pickerAction(.testButton(packet)):
      print("-----> ApiCore: Test, packet = \(packet!.nickname)")
      return .none
      
    case .pickerAction(_):
      // IGNORE ALL OTHERS
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Upstream actions (Login)

    case .loginAction(.cancelButton):
      print("-----> Login: Cancel button")
      state.loginState = nil
      return .none
      
    case let .loginAction(.loginButton(result)):
      startWanListener(&state, loginResult: result)
      return .none
      
    case .loginClosed:
      state.loginState = nil
      print("-----> ApiViewer: Login closed")
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Alert actions
      
    case .alertDismissed:
      state.alert = nil
      return .none
    }
  }
)
//  .debug("API ")

private func startListening(_ state: inout ApiState) {
  if state.discovery == nil { state.discovery = Discovery.sharedInstance }
  if state.connectionMode == .local || state.connectionMode == .both {
    do {
      try state.discovery?.startLanListener()
      
    } catch LanListenerError.kSocketError {
      state.alert = AlertView(title: "Discovery: Lan Listener, Failed to open a socket")
    } catch LanListenerError.kReceivingError {
      state.alert = AlertView(title: "Discovery: Lan Listener, Failed to start receiving")
    } catch {
      state.alert = AlertView(title: "Discovery: Lan Listener, unknown error")
    }
  }
  if state.connectionMode == .smartlink || state.connectionMode == .both {
    do {
      try state.discovery?.startWanListener(smartlinkEmail: state.smartlinkEmail, force: state.wanLogin)
      
    } catch WanListenerError.kFailedToObtainIdToken {
      state.loginState = LoginState(email: state.smartlinkEmail)
      
    } catch WanListenerError.kFailedToConnect {
      state.alert = AlertView(title: "Discovery: Wan Listener, Failed to Connect")
    } catch {
      state.alert = AlertView(title: "Discovery: Wan Listener, unknown error")
    }
  }
}

private func startWanListener(_ state: inout ApiState, loginResult: LoginResult) {
  state.smartlinkEmail = loginResult.email
  state.loginState = nil
  do {
    try state.discovery?.startWanListener(using: loginResult)
    
  } catch WanListenerError.kFailedToObtainIdToken {
    state.alert = AlertView(title: "Discovery: Wan Listener, Failed to Obtain IdToken")
  } catch WanListenerError.kFailedToConnect {
    state.alert = AlertView(title: "Discovery: Wan Listener, Failed to Connect")
  } catch {
    state.alert = AlertView(title: "Discovery: Wan Listener, unknown error")
  }
}
