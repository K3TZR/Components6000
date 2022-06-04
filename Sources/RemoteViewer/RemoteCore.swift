//
//  RemoteCore.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 2/26/22.
//

import Foundation
import ComposableArchitecture
import Combine

import SecureStorage
import LoginView
import ProgressView

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

struct RelaySubscriptionId: Hashable {}

public struct RelayScript: Equatable {
  public var type: ScriptType
  public var duration: Float
  public var source: String
  public var msg: String
}

public enum ScriptType: String {
  case cycleOff = "cycle_off"
  case cycleOn = "cycle_on"
}

public enum RelayProperty: String {
  case critical
  case cycleDelay = "cycle_delay"
  case name
  case status = "state"
}

// ----------------------------------------------------------------------------
// MARK: - State, Actions & Environment

public struct RemoteState: Equatable {
  
  public init(
    _ heading: String = "Relay Status",
    alertState: AlertState<RemoteAction>? = nil,
    progressState: ProgressState? = nil,
    relays: IdentifiedArrayOf<Relay> = initialRelays
  )
  {
    self.heading = heading
    self.alertState = alertState
    self.progressState = progressState
    self.relays = relays
  }
  public var alertState: AlertState<RemoteAction>?
  public var forceUpdate = false
  public var heading: String
  public var relays = initialRelays
  public var progressState: ProgressState?
  public var secureStore: SecureStore?
  public var loginState: LoginState?
  public var user: String = "admin"
  public var pwd: String?
  public var loginSuccessful = false
}

public enum RemoteAction: Equatable {
  // initialization
  case onAppear

  // UI controls
  case allOff
  case getScripts
  case getRelays
  case runScript(RelayScript)
  case setScripts

  // subview/sheet/alert related
  case alertDismissed
  case loginAction(LoginAction)
  case progressAction(ProgressAction)
  case relay(id: Relay.ID, action: RelayAction)

  // Effects related
  case getPropertyCompleted(Bool, String)
  case getRelaysCompleted(Bool, IdentifiedArrayOf<Relay>)
  case getScriptsCompleted(Bool, String)
  case runScriptCompleted(Bool, RelayScript)
  case setPropertyCompleted(Bool, String)
  case setScriptsCompleted(Bool)
}

public struct RemoteEnvironment {
  public init() {}
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

public let remoteReducer = Reducer<RemoteState, RemoteAction, RemoteEnvironment>.combine(
  loginReducer
    .optional()
    .pullback(
      state: \RemoteState.loginState,
      action: /RemoteAction.loginAction,
      environment: { _ in LoginEnvironment() }
    ),
  progressReducer
    .optional()
    .pullback(
      state: \RemoteState.progressState,
      action: /RemoteAction.progressAction,
      environment: { _ in ProgressEnvironment() }
    ),
  relayReducer.forEach(
    state: \.relays,
    action: /RemoteAction.relay(id:action:),
    environment: { _ in RelayEnvironment() }
  ),
  Reducer { state, action, environment in
    
    switch action {
      // ----------------------------------------------------------------------------
      // MARK: - Initialization
      
    case .onAppear:
      let secureStore = SecureStore(service: "RemoteViewer")
      let pwd = secureStore.get(account: state.user)
      if pwd != nil {
        state.pwd = pwd
        return Effect(value: .getRelays)
      
      } else {
        state.loginState = LoginState(heading: "Please Login", user: state.user, service: "RemoteViewer")
        return .none
      }
      
      // ----------------------------------------------------------------------------
      // MARK: - RemoteView UI actions
      
    case .allOff:
      state.progressState = ProgressState(msg: "while all relays are switched off")
      return setProperty( state, property: .status, at: nil, value: "false")
    
    case .getScripts:
      state.progressState = ProgressState(msg: "while scripts are downloaded")
      return getScripts( state )

    case .getRelays:
      state.progressState = ProgressState(msg: "while relays are fetched")
//      return getRelays( state )
      return getRelaysAsync( state )

    case .runScript(let script):
      state.progressState = ProgressState(msg: script.msg, duration: script.duration)
      return runScript( state, script: script)
      
    case .setScripts:
      state.progressState = ProgressState(msg: "while scripts are uploaded")
      return setScripts( state, scripts: scripts )

      // ----------------------------------------------------------------------------
      // MARK: - Action sent when an Alert is closed
      
    case .alertDismissed:
      state.alertState = nil
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent by effects
                  
    case .getPropertyCompleted(let success, let text):
      state.progressState = nil
      if !success { state.alertState = AlertState(title: TextState("GET failure: \(text)")) }
      return .none
            
    case .setPropertyCompleted(let success, let text):
      state.progressState = nil
      if !success { state.alertState = AlertState(title: TextState("POST failure: \(text)")) }
      return getRelays( state )
      
    case .getRelaysCompleted(let success, let relays):
      state.progressState = nil
      if success {
        state.loginSuccessful = true
        state.relays = relays
        state.forceUpdate.toggle()
      } else {
        state.loginSuccessful = false
        state.alertState = AlertState(title: TextState("Relay load failure"))
      }
      return .none
      
    case .getScriptsCompleted(let success, let scripts):
      state.progressState = nil
      if !success { state.alertState = AlertState(title: TextState("Get Scripts failure"))}
      return .none
      
    case .runScriptCompleted(let success, let script):
      state.progressState = nil
      if success {
        return getRelays( state )
      } else {
        state.alertState = AlertState(title: TextState("Run \(script.type.rawValue) Script failure"))
      }
      return .none

    case .setScriptsCompleted(let success):
      state.progressState = nil
      if success {
        return getRelays( state )
      
      } else {
        state.alertState = AlertState(title: TextState("Set Scripts failure"))
        return .none
      }
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent upstream by the RelayView (i.e. RelayView -> RemoteView)

    case .relay(let id, .nameChanged):
      if state.loginSuccessful {
        state.progressState = ProgressState(msg: "while the name is changed")
        return setProperty(state, property: .name, at: id, value: state.relays[id: id]!.name)
      } else {
        state.loginState = LoginState(heading: "Please Login", user: state.user, service: "RemoteViewer")
        return .none
      }

    case .relay(let id, .toggleStatus):
      if state.loginSuccessful {
        state.progressState = ProgressState(msg: "while the state is changed")
        return setProperty( state, property: .status, at: id, value: state.relays[id: id]!.status ? "false" : "true")
      } else {
        state.loginState = LoginState(heading: "Please Login", user: state.user, service: "RemoteViewer")
        return .none
      }

    case .relay(id: let id, action: _):
      // ignore all others
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent upstream by the ProgressView (i.e. ProgressView -> RemoteView)
      
    case .progressAction(.cancel):
      state.progressState = nil
      return .none
    
    case .progressAction(.completed):
      print("-----> Completed")
      state.progressState = nil
      return .none

    case .progressAction(_):
      // ignore all others
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent upstream by the LoginView (i.e. LoginView -> RemoteView)
      
    case .loginAction(.cancelButton):
      state.loginState = nil
      return .none

    case .loginAction(.loginButton):
      state.loginState = nil      
      let secureStore = SecureStore(service: "RemoteViewer")
      state.pwd = secureStore.get(account: "pwd")
      return Effect(value: .getRelays)
    
    case .loginAction(_):
      // ignore all others
      return .none
    }
  }
)


// ----------------------------------------------------------------------------
// MARK: - Helper functions

public var initialRelays: IdentifiedArrayOf<Relay> = [
  Relay( name: "Relay 0" ),
  Relay( name: "Relay 1" ),
  Relay( name: "Relay 2" ),
  Relay( name: "Relay 3" ),
  Relay( name: "Relay 4" ),
  Relay( name: "Relay 5" ),
  Relay( name: "Relay 6" ),
  Relay( name: "Relay 7" )
]
