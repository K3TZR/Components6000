//
//  RemoteView.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 2/26/22.
//

import ComposableArchitecture
import SwiftUI

import LoginView
import ProgressView

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct RemoteView: View {
  let store: Store<RemoteState, RemoteAction>
  
  public init(store: Store<RemoteState, RemoteAction>) {
    self.store = store
  }
  
  public var body: some View {
    
    WithViewStore(store) { viewStore in
      VStack {
        RemoteViewHeading(store: store)
        RemoteViewBody(store: store)
        RemoteViewFooter(store: store)
      }
      // alert dialogs
      .alert(
        self.store.scope(state: \.alertState),
        dismiss: .alertDismissed
      )

      // Login sheet
      .sheet(
        isPresented: viewStore.binding(
          get: { $0.loginState != nil },
          send: RemoteAction.loginAction(.cancelButton)),
        content: {
          IfLetStore(
            store.scope(state: \.loginState, action: RemoteAction.loginAction),
            then: LoginView.init(store:)
          )
        }
      )
    }
    .padding(.horizontal)
  }
}

public struct RemoteViewHeading: View {
  let store: Store<RemoteState, RemoteAction>
  
  public var body: some View {
    
    WithViewStore(store) { viewStore in
      VStack {
        Text(viewStore.heading).font(.title).padding(.bottom)
        HStack {
          Text("Name").frame(width: 300, alignment: .leading)
          Group {
            Text("State")
            Text("Locked")
          }
          .frame(width: 100, alignment: .center)
        }
      }
      .font(.title2)
      .onAppear() { viewStore.send(.onAppear) }

      // Progress sheet
      .sheet(
        isPresented: viewStore.binding(
          get: { $0.progressState != nil },
          send: RemoteAction.progressAction(.cancel)),
        content: {
          IfLetStore(
            store.scope(state: \.progressState, action: RemoteAction.progressAction),
            then: ProgressView.init(store:)
          )
        }
      )
    }
    
    Divider().background(Color(.red))
  }
}

public struct RemoteViewBody: View {
  let store: Store<RemoteState, RemoteAction>
  
  public var body: some View {
    
    VStack {
      ForEachStore(
        self.store.scope(state: \.relays, action: RemoteAction.relay(id:action:)),
        content: RelayView.init(store:)
      )
    }
  }
}

public struct RemoteViewFooter: View {
  let store: Store<RemoteState, RemoteAction>
  
  public var body: some View {
    
    WithViewStore(store) { viewStore in
      Spacer()
      Divider().background(Color(.red))
      HStack(spacing: 60) {
        Button("Refresh") { viewStore.send(.getRelays) }.disabled(viewStore.loginSuccessful == false || viewStore.progressState != nil)
        Button("All Off") { viewStore.send(.allOff) }.disabled(viewStore.loginSuccessful == false || viewStore.progressState != nil)
        Spacer()
        Button("Set Scripts") { viewStore.send(.setScripts) }.disabled(viewStore.loginSuccessful == false || viewStore.progressState != nil)
        Button("Get Scripts") { viewStore.send(.getScripts) }.disabled(viewStore.loginSuccessful == false || viewStore.progressState != nil)
        Spacer()
        Button("Cycle ON") { viewStore.send(.runScript(cycleOnScript)) }.disabled(viewStore.loginSuccessful == false || viewStore.progressState != nil)
        Button("Cycle OFF") { viewStore.send(.runScript(cycleOffScript)) }.disabled(viewStore.loginSuccessful == false || viewStore.progressState != nil)
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct RemoteView_Previews: PreviewProvider {
  
  static var previews: some View {
    RemoteView(
      store: Store(
        initialState: RemoteState("Relay Status"),
        reducer: remoteReducer,
        environment: RemoteEnvironment()
      )
    )
  }
}

public var testRelays: [Relay] = [
  Relay(name: "Main power"),
  Relay(name: "---"),
  Relay(name: "---"),
  Relay(name: "---"),
  Relay(name: "Astron power"),
  Relay(name: "Rotator power"),
  Relay(name: "Linear power"),
  Relay(name: "Remote power on")
]
