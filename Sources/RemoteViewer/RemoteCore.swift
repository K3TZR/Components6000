//
//  RemoteCore.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 2/26/22.
//

import Foundation
import ComposableArchitecture
import Combine

import Shared

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
  
  public init(_ heading: String = "Relay Status") {
    self.heading = heading
  }
  public var alert: AlertState<RemoteAction>?
  public var forceUpdate = false
  public var heading: String
  public var relays = initialRelays
  public var progressState: ProgressState? = nil
}

public enum RemoteAction: Equatable {
  // initialization
  case onAppear

  // UI controls
  case allOff
//  case cycleOn
//  case cycleOff
  case getScripts
  case getRelays
  case runScript(RelayScript)
  case setScripts

  // subview/sheet/alert related
  case alertDismissed
  case progressAction(ProgressAction)   // placeholder, never issued
  case relay(id: Relay.ID, action: RelayAction)

  // Effects related
  case getPropertyCompleted(Bool, String)
  case getRelaysCompleted(Bool, IdentifiedArrayOf<Relay>)
  case getScriptsCompleted(Bool, String)
  case runScriptCompleted(Float, Bool, RelayScript)
  case setPropertyCompleted(Bool, String)
  case setScriptsCompleted(Bool)
}

public struct RemoteEnvironment {
  public init() {}
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

public let remoteReducer = Reducer<RemoteState, RemoteAction, RemoteEnvironment>.combine(
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
      return getRelays( "admin", "ruwn1viwn_RUF_zolt" )
      
      // ----------------------------------------------------------------------------
      // MARK: - RemoteView UI actions
      
    case .allOff:
      state.progressState = ProgressState(title: "while all relays are switched off")
      return setProperty(.status, at: nil, value: "false", "admin", "ruwn1viwn_RUF_zolt" )
    
    case .getScripts:
      state.progressState = ProgressState(title: "while scripts are downloaded")
      return getScripts( "admin", "ruwn1viwn_RUF_zolt" )

    case .getRelays:
      state.progressState = ProgressState(title: "while relays are fetched")
      return getRelays( "admin", "ruwn1viwn_RUF_zolt" )
     
    case .runScript(let script):
      state.progressState = ProgressState(title: script.msg, duration: script.duration)
      return runScript( script, "admin", "ruwn1viwn_RUF_zolt" )
      
    case .setScripts:
      state.progressState = ProgressState(title: "while scripts are uploaded")
      return setScripts( scripts, "admin", "ruwn1viwn_RUF_zolt" )

      // ----------------------------------------------------------------------------
      // MARK: - Action sent when an Alert is closed
      
    case .alertDismissed:
      state.alert = nil
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent by effects
                  
    case .getPropertyCompleted(let success, let text):
      sleep(3)
      state.progressState = nil
      if !success { state.alert = AlertState(title: TextState("GET failure: \(text)")) }
      return .none
            
    case .setPropertyCompleted(let success, let text):
      sleep(3)
      state.progressState = nil
      if !success { state.alert = AlertState(title: TextState("POST failure: \(text)")) }
      return getRelays( "admin", "ruwn1viwn_RUF_zolt" )
      
    case .getRelaysCompleted(let success, let relays):
      state.progressState = nil
      if success {
        state.relays = relays
        state.forceUpdate.toggle()
      } else {
        state.alert = AlertState(title: TextState("Relay load failure"))
      }
      return .none
      
    case .getScriptsCompleted(let success, let scripts):
      sleep(3)
      state.progressState = nil
      if !success { state.alert = AlertState(title: TextState("Get Scripts failure"))}
      return .none
      
    case .runScriptCompleted(let duration, let success, let script):
      sleep(UInt32(duration))
      state.progressState = nil
      if success {
        return getRelays( "admin", "ruwn1viwn_RUF_zolt" )
      } else {
        state.alert = AlertState(title: TextState("Run \(script.type.rawValue) Script failure"))
      }
      return .none

    case .setScriptsCompleted(let success):
      sleep(3)
      state.progressState = nil
      if success {
        return getRelays( "admin", "ruwn1viwn_RUF_zolt" )
      
      } else {
        state.alert = AlertState(title: TextState("Set Scripts failure"))
        return .none
      }
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent upstream by the RelayView (i.e. RelayView -> RemoteView)

    case .relay(let id, .nameChanged):
      state.progressState = ProgressState(title: "while the name is changed")
      return setProperty(.name, at: state.relays.index(id: id), value: state.relays[id: id]!.name, "admin", "ruwn1viwn_RUF_zolt")

    case .relay(let id, .toggleStatus):
      state.progressState = ProgressState(title: "while the state is changed")
      return setProperty(.status, at: state.relays.index(id: id), value: state.relays[id: id]!.name, "admin", "ruwn1viwn_RUF_zolt")

    case .relay(id: let id, action: _):
      // ignore all others
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent upstream by the ProgressView (i.e. ProgressView -> RemoteView)
      
    case .progressAction(.cancel):
      state.progressState = nil
      return .none
    
    case .progressAction(_):
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

extension URLRequest {
  mutating func setBasicAuth(username: String, password: String) {
    let encodedAuthInfo = String(format: "%@:%@", username, password)
      .data(using: String.Encoding.utf8)!
      .base64EncodedString()
    addValue("Basic \(encodedAuthInfo)", forHTTPHeaderField: "Authorization")
  }
}


