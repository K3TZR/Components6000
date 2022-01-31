//
//  BottomButtonsView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

struct BottomButtonsView: View {
  let store: Store<ApiState, ApiAction>

  @State var fontSize: CGFloat = 12

  var body: some View {

    WithViewStore(self.store) { viewStore in
      HStack {
        Stepper("Font Size",
                value: viewStore.binding(
                  get: \.fontSize,
                  send: { value in .fontSizeStepper(value) }),
                in: 8...14)
        Text(String(format: "%2.0f", viewStore.fontSize)).frame(alignment: .leading)
        Spacer()
        Button("Reverse") { viewStore.send(.reverseButton)}
        Spacer()
        HStack(spacing: 40) {
          Toggle("Clear on Connect", isOn: viewStore.binding(get: \.clearOnConnect, send: .toggleButton(\.clearOnConnect)))
          Toggle("Clear on Disconnect", isOn: viewStore.binding(get: \.clearOnDisconnect, send: .toggleButton(\.clearOnDisconnect)))
          Button("Clear Now") { viewStore.send(.clearNowButton)}
        }
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct BottomButtonsView_Previews: PreviewProvider {
  static var previews: some View {
    BottomButtonsView(
      store: Store(
        initialState: ApiState(domain: "net.k3tzr", appName: "Api6000"),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
