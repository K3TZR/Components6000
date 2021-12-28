//
//  LoginCore.swift
//  Components6000/Login
//
//  Created by Douglas Adams on 12/28/21.
//

import ComposableArchitecture

public struct LoginResult: Equatable {
  
  public init(_ email: String, pwd: String) {
    self.email = email
    self.pwd = pwd
  }
  var email = ""
  var pwd = ""
}

public struct LoginState: Equatable {
  var heading = "Smartlink Login"
}

public enum LoginAction: Equatable {
  case cancelButton
  case loginButton(LoginResult)
}

public struct LoginEnvironment {
}

let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment>
  { state, action, environment in
  
  return .none
  }
