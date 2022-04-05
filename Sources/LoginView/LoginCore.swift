//
//  LoginCore.swift
//  Components6000/Login
//
//  Created by Douglas Adams on 12/28/21.
//

import ComposableArchitecture

import SecureStorage

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

public struct LoginResult: Equatable {
  
  public init(_ user: String, pwd: String) {
    self.user = user
    self.pwd = pwd
  }
  public var user = ""
  public var pwd = ""
}

// ----------------------------------------------------------------------------
// MARK: - State, Actions & Environment

public struct LoginState: Equatable {
  
  public init(
    heading: String = "Please Login",
    user: String = "",
    pwd: String = "",
    userLabel: String = "User",
    pwdLabel: String = "Pasword",
    service: String? = nil
  )
  {
    self.heading = heading
    self.user = user
    self.pwd = pwd
    self.userLabel = userLabel
    self.pwdLabel = pwdLabel
    self.service = service
  }
  var heading: String
  @BindableState var user: String
  @BindableState var pwd: String
  var userLabel: String
  var pwdLabel: String
  var service: String?
}

public enum LoginAction: BindableAction, Equatable {
  
  // UI controls
  case cancelButton
  case loginButton
//  case loginComplete(String, String)
  case binding(BindingAction<LoginState>)
}

public struct LoginEnvironment {
  
  public init() {}
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

public let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment>
  { state, action, environment in
    
    switch action {

    case .cancelButton:
      return .none

    case .loginButton:
//      return Effect(value: .loginComplete(state.user, state.pwd))
//
//    case .loginComplete(let user, let pwd):
      if state.service != nil {
        let secureStore = SecureStore(service: state.service!)
        _ = secureStore.set(account: "user", data: state.user)
        _ = secureStore.set(account: "pwd", data: state.pwd)
      }
      return .none

    case .binding(_):
      return .none
    }
//    return .none
  }
  .binding()
