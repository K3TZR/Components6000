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
  
  public init(_ email: String, pwd: String) {
    self.email = email
    self.pwd = pwd
  }
  public var email = ""
  public var pwd = ""
}

// ----------------------------------------------------------------------------
// MARK: - State, Actions & Environment

public struct LoginState: Equatable {
  
  public init(heading: String = "Smartlink Login", email: String = "", pwd: String = "") {
    self.email = email
    self.heading = heading
    self.pwd = pwd
  }
  @BindableState var email: String
  @BindableState var pwd: String
  @BindableState var heading: String
}

public enum LoginAction: BindableAction, Equatable {
  
  // UI controls
  case cancelButton
  case loginButton
  case binding(BindingAction<LoginState>)
}

public struct LoginEnvironment {
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment>
  { state, action, environment in
    
//    switch action {
//    case .binding(\.$email):
//      print("email = \(state.email)")
//      return .none
//
//    case .binding(\.$pwd):
//      print("pwd = \(state.pwd)")
//      return .none
//
//    case .cancelButton:
//      print("cancel button")
//      return .none
//
//    case .loginButton:
//      print("login button, email = \(state.email), pwd = \(state.pwd)")
//      return .none
//
//    case .binding(_):
//      print("other binding")
//      return .none
//    }
    return .none
  }
  .binding()
