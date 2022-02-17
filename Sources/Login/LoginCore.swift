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
  var email: String
  var heading: String
  var pwd: String
}

public enum LoginAction: Equatable {
  // UI controls
  case cancelButton
  case loginButton(LoginResult)
}

public struct LoginEnvironment {
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment>
  { state, action, environment in
    return .none
  }
