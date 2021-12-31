//
//  LoginView.swift
//  Components6000/Login
//
//  Created by Douglas Adams on 12/28/21.
//

import ComposableArchitecture
import SwiftUI

import Login

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct LoginView: View {
  let store: Store<LoginState, LoginAction>
  
  @State var heading = "Smartlink Login"
  @State var email = ""
  @State var pwd = ""
  
  public init(store: Store<LoginState, LoginAction>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack(spacing: 30) {
        Text(heading).font(.title)
        Divider()
        
        HStack {
          VStack(alignment: .leading, spacing: 40) {
            Text("Email:")
            Text("Password:")
          }
          
          VStack(alignment: .leading, spacing: 40) {
            TextField("", text: $email)
            SecureField("", text: $pwd)
          }
        }
        
        HStack(spacing: 60) {
          Button("Cancel") { viewStore.send(.cancelButton) }
          .keyboardShortcut(.cancelAction)
          
          Button("Log in") { viewStore.send(.loginButton(LoginResult(email, pwd: pwd))) }
          .disabled(email == "" || pwd == "")
          .keyboardShortcut(.defaultAction)
        }
      }
      .frame(minWidth: 400)
      .padding()
    }
  }
}
// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    LoginView(
      store: Store(
        initialState: LoginState(),
        reducer: loginReducer,
        environment: LoginEnvironment()
      )
    )
  }
}
