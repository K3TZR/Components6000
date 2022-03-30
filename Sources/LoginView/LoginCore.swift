//
//  LoginCore.swift
//  Components6000/Login
//
//  Created by Douglas Adams on 12/28/21.
//

import ComposableArchitecture

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
    pwdLabel: String = "Pasword"
  )
  {
    self.heading = heading
    self.user = user
    self.pwd = pwd
    self.userLabel = userLabel
    self.pwdLabel = pwdLabel
  }
  var heading: String
  @BindableState var user: String
  @BindableState var pwd: String
  var userLabel: String
  var pwdLabel: String
}

public enum LoginAction: BindableAction, Equatable {
  
  // UI controls
  case cancelButton
  case loginButton(LoginResult)
  case binding(BindingAction<LoginState>)
}

public struct LoginEnvironment {
  
  public init() {}
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

public let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment>
  { state, action, environment in
    
//    switch action {
//
//    case .cancelButton:
//      return .none
//
//    case .loginButton(let credentials):
//      return .none
//
//    case .binding(_):
//      return .none
//    }
    return .none
  }
//  .binding()
