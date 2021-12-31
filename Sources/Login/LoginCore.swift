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
  public var email = ""
  public var pwd = ""
}

public struct LoginState: Equatable {
  
  public init(heading: String = "Smartlink Login") {
    self.heading = heading
  }
  
  var heading: String
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
