//
//  TopButtonsView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

struct TopButtonsView: View {
  let store: Store<ApiState, ApiAction>

  @State var smartlinkIsLoggedIn = false
  @State var smartlinkIsEnabled = false

  var body: some View {

    WithViewStore(self.store) { viewStore in
      HStack(spacing: 30) {
        Button(viewStore.connectedPacket == nil ? "Start" : "Stop") {
          viewStore.send(.startStopButton)
        }
        .keyboardShortcut(viewStore.connectedPacket == nil ? .defaultAction : .cancelAction)

        HStack(spacing: 20) {
          Toggle("Gui", isOn: viewStore.binding(get: \.isGui, send: .button(\.isGui)))
          Toggle("Times", isOn: viewStore.binding(get: \.showTimes, send: .button(\.showTimes)))
          Toggle("Pings", isOn: viewStore.binding(get: \.showPings, send: .button(\.showPings)))
          Toggle("Replies", isOn: viewStore.binding(get: \.showReplies, send: .button(\.showReplies)))
          Toggle("WanLogin", isOn: viewStore.binding(get: \.wanLogin, send: .button(\.wanLogin))).disabled(viewStore.connectionMode == .local)
        }

        Spacer()
        Picker("", selection: viewStore.binding(
          get: \.connectionMode,
          send: { .modePicker($0) }
        )) {
          Text("Local").tag(ConnectionMode.local)
          Text("Smartlink").tag(ConnectionMode.smartlink)
          Text("Both").tag(ConnectionMode.both)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 200)

        Spacer()
        Button("Clear Default") { viewStore.send(.clearDefaultButton) }
        .disabled(viewStore.defaultConnection == nil)
      }
      .alert(
        item: viewStore.binding(
          get: { $0.alert },
          send: .alertDismissed
        ),
        content: { Alert(title: Text($0.title)) }
      )
      .onAppear() { viewStore.send(.onAppear) }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct TopButtonsView_Previews: PreviewProvider {
  static var previews: some View {
    TopButtonsView(
      store: Store(
        initialState: ApiState(),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
