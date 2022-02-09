//
//  TopButtonsView.swift
//  Components6000/ApiViewer/Subviews/ViewerSubViews
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
        Button(viewStore.radio == nil ? "Start" : "Stop") {
          viewStore.send(.startStopButton)
        }
        .keyboardShortcut(viewStore.radio == nil ? .defaultAction : .cancelAction)

        HStack(spacing: 20) {
          Toggle("Gui", isOn: viewStore.binding(get: \.isGui, send: .toggleButton(\.isGui)))
          Toggle("Times", isOn: viewStore.binding(get: \.showTimes, send: .toggleButton(\.showTimes)))
          Toggle("Pings", isOn: viewStore.binding(get: \.showPings, send: .toggleButton(\.showPings)))
        }

        Spacer()
        Picker("", selection: viewStore.binding(
          get: \.connectionMode,
          send: { .connectionModePicker($0) }
        )) {
          Text("Local").tag(ConnectionMode.local)
          Text("Smartlink").tag(ConnectionMode.smartlink)
          Text("Both").tag(ConnectionMode.both)
          Text("None").tag(ConnectionMode.none)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 200)

        Spacer()
        Button("Force Login") {viewStore.send(.forceLoginButton)}
        .disabled(viewStore.connectionMode == .local || viewStore.connectionMode == .none)
        Button("Clear Default") { viewStore.send(.clearDefaultButton) }
        .disabled(viewStore.defaultConnection == nil)
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct TopButtonsView_Previews: PreviewProvider {
  static var previews: some View {
    TopButtonsView(
      store: Store(
        initialState: ApiState(domain: "net.k3tzr", appName: "Api6000"),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
